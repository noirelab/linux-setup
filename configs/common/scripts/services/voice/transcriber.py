"""Local speech-to-text: Silero VAD for endpointing, faster-whisper for text.

Ported from the Chico dictation tool, with one structural change: capture and
transcription run on a worker thread and every API call returns immediately.

That split is the fix for long audio, not a refactor. When a single request
covered "record until silence, then transcribe", its timeout had to cover how
long the human spoke, the caller had 25 seconds to decide between a long
sentence and a hung service, and chose wrong every time past 25 seconds. It
also meant a recording that ran past the hard cap was *discarded* with an
error, throwing away audio the user had already produced. Here nothing is
bounded by how long you talk: the cap stops the microphone and transcribes what
it has, and the client learns the outcome by asking.
"""

from __future__ import annotations

import os
import threading
import time
from collections import deque
from dataclasses import dataclass, field

import numpy as np

SAMPLING_RATE = 16000
CHUNK_SIZE = 512


def _env_float(name: str, default: float) -> float:
    try:
        return float(os.environ[name])
    except (KeyError, ValueError):
        return default


# Silence that ends a recording. Longer than Chico's 1.5s because there the
# only way to stop was to stop talking; here the user has an explicit stop, so
# the auto-stop can afford to let someone pause and think mid-thought.
SILENCE_DURATION = _env_float("MAEGOR_VOICE_SILENCE", 2.5)

# Hard cap on one recording. Reached, it transcribes, it does not discard.
MAX_RECORDING = _env_float("MAEGOR_VOICE_MAX_SECONDS", 900.0)

# How long an open microphone waits for a first word before giving up, so a
# mis-hit shortcut does not hold the mic for the full cap.
LEAD_IN = _env_float("MAEGOR_VOICE_LEAD_IN", 20.0)

# Hardcoded rather than auto-detected, as in Chico: on a single dictated phrase
# Whisper's language detection is markedly less reliable than being told, and
# being told the wrong language is a whole transcript of nonsense. Set
# MAEGOR_VOICE_LANGUAGE="" for auto-detection.
LANGUAGE = os.environ.get("MAEGOR_VOICE_LANGUAGE", "pt") or None

MODEL_ID = os.environ.get("MAEGOR_VOICE_MODEL", "turbo")

# Input device, by name (what the app sends) or by sounddevice index (for
# setting it by hand). Unset means the system default, which on a desktop with
# speakers, not a headset, is how the mic ends up hearing whatever else is
# playing and "silence" never comes.
_DEVICE_ENV = os.environ.get("MAEGOR_VOICE_DEVICE")
DEVICE: int | str | None = None
if _DEVICE_ENV:
    try:
        DEVICE = int(_DEVICE_ENV)
    except ValueError:
        DEVICE = _DEVICE_ENV

VAD_THRESHOLD = 0.5

# Whisper emits these into silence. The list is a heuristic and always will be
#, it cannot tell a hallucinated "obrigado" from a spoken one.
# ponytail: substring-free exact match, keeps false positives near zero.
HALLUCINATIONS = {
    "thank you.", "thank you", "thanks.", "thanks for watching.", "subscribe.",
    "obrigado.", "obrigado", "obrigada.", "legendas pela comunidade amara.org",
    "legendado pela comunidade amara.org", "tchau.", "...",
    # The classic decode-on-noise outputs, seen with the fallback passes on
    # a fan-and-keyboard room: Whisper turns a loud background into a phrase.
    "entertain us.", "entertain us", "you.", "you", "um.", "um", "uh.", "uh",
}

# What the client can see. `listening` is an open microphone that has not heard
# a word yet; `recording` has.
IDLE = "idle"
# ~3s of history at CHUNK_SIZE, which is what the meter draws.
LEVEL_HISTORY = 96

LISTENING = "listening"
RECORDING = "recording"
TRANSCRIBING = "transcribing"
DONE = "done"
ERROR = "error"


@dataclass
class Status:
    state: str = IDLE
    seconds: float = 0.0
    text: str = ""
    error: str | None = None
    model_ready: bool = False
    device: str = "unknown"
    # Loudness of the most recent chunks, oldest first, 0.0 to 1.0. It is the
    # RMS of the audio actually captured, not a guess: a meter that animates
    # without listening tells the user the microphone is working at exactly
    # the moment they are checking whether it is. The caller polls slower than
    # this fills, so a history is sent rather than one value, and the UI plays
    # it back instead of stepping once per poll.
    levels: list[float] = field(default_factory=list)


@dataclass
class _Take:
    """One recording in flight."""

    stop: threading.Event = field(default_factory=threading.Event)
    cancelled: bool = False


class VoiceTranscriber:
    def __init__(self, open_stream=None, load_models: bool = True):
        # Both injected in tests, so the state machine can be exercised without
        # a microphone, a GPU, or a 3GB model download.
        self._open_stream = open_stream or _open_microphone
        self._lock = threading.Lock()
        self._status = Status()
        self._take: _Take | None = None
        self._model = None
        # Takes one float32 chunk and returns a speech probability. `None`
        # until the model lands; a take waits for it before opening the mic,
        # because a take without an auto-stop records to the cap.
        self._vad = None
        self._vad_reset = None
        # Set once `_vad` is published (or the model load failed and there
        # will never be one). Takes wait on it, not on `_model_ready`: the
        # auto-stop needs only the VAD, transcription needs Whisper too.
        self._vad_ready = threading.Event()
        self._model_ready = threading.Event()
        if load_models:
            threading.Thread(target=self._load_models, daemon=True).start()

    # -- lifecycle ---------------------------------------------------------

    def _load_models(self) -> None:
        try:
            import torch
            from faster_whisper import WhisperModel

            # VAD first, published under the lock it reads under. Endpointing
            # and transcription are independent; a take only waits for the
            # VAD, so the first take after launch stops on silence as soon as
            # it can, while Whisper still downloads behind it. Loading them
            # together and publishing both only at the end made the first take
            # after launch deaf, running to the cap or the user's hand.
            silero, _ = torch.hub.load(
                repo_or_dir="snakers4/silero-vad",
                model="silero_vad",
                force_reload=False,
                trust_repo=True,
            )
            with self._lock:
                self._vad_reset = silero.reset_states
                self._vad = lambda chunk: float(
                    silero(torch.from_numpy(chunk), SAMPLING_RATE)
                )
            self._vad_ready.set()
            device = "cuda" if torch.cuda.is_available() else "cpu"
            model = WhisperModel(
                MODEL_ID,
                device=device,
                compute_type="float16" if device == "cuda" else "int8",
            )
        except Exception as exc:  # noqa: BLE001, surfaced to the UI verbatim
            with self._lock:
                self._status.error = f"speech model failed to load: {exc}"
                self._status.state = ERROR
            # Wake takes waiting on the VAD so they can report the failure
            # instead of hanging in "listening" forever.
            self._vad_ready.set()
            return

        self._model = model
        with self._lock:
            self._status.model_ready = True
            self._status.device = device
        self._model_ready.set()

    # -- commands ----------------------------------------------------------

    def start(self) -> Status:
        """Opens the microphone. Returns at once; the mic runs on a worker.

        The take waits for the VAD before opening the mic, a take without an
        auto-stop records to the cap, but not for Whisper: transcription can
        wait, endpointing cannot.
        """
        with self._lock:
            if self._status.state in (LISTENING, RECORDING, TRANSCRIBING):
                return self._snapshot()
            take = _Take()
            self._take = take
            self._status = Status(
                state=LISTENING,
                model_ready=self._model_ready.is_set(),
                device=self._status.device,
            )
        threading.Thread(target=self._run, args=(take,), daemon=True).start()
        return self.status()

    def stop(self) -> Status:
        """Ends capture. Transcription continues on the worker."""
        with self._lock:
            take = self._take
        if take:
            take.stop.set()
        return self.status()

    def cancel(self) -> Status:
        """Ends capture and throws the audio away."""
        with self._lock:
            take = self._take
            if take:
                take.cancelled = True
            self._status = Status(
                model_ready=self._model_ready.is_set(), device=self._status.device
            )
        if take:
            take.stop.set()
        return self.status()

    def status(self) -> Status:
        with self._lock:
            return self._snapshot()

    def _snapshot(self) -> Status:
        return Status(**vars(self._status))

    def _set(self, take: _Take | None = None, **fields) -> None:
        """Applies a status update, unless the take that produced it is gone.

        The guard is not belt-and-braces. Without it the worker's next progress
        tick overwrites the idle status `cancel` just wrote, and a cancelled
        recording goes on reporting itself as live; checking currency and then
        writing under two separate locks loses the same race more rarely.
        """
        with self._lock:
            if take is not None and (self._take is not take or take.cancelled):
                return
            for key, value in fields.items():
                setattr(self._status, key, value)

    def _current(self, take: _Take) -> bool:
        """False once this take has been cancelled or replaced."""
        with self._lock:
            return self._take is take and not take.cancelled

    # -- worker ------------------------------------------------------------

    def _run(self, take: _Take) -> None:
        # No auto-stop, no take: the mic does not open until the VAD is
        # published. A take that opened earlier would record to the cap or the
        # user's hand, the bug this wait exists for.
        self._vad_ready.wait()
        with self._lock:
            vad = self._vad
            load_error = self._status.error
        if take.stop.is_set():
            # Stopped while the model loaded; the mic never opened, so there
            # is no audio to transcribe or discard.
            if self._current(take):
                self._set(take, state=DONE, text="", seconds=0.0)
            return
        if not self._current(take):
            return
        if vad is None:
            # The model load failed; its error is already on the status, and
            # taking the mic would record with no way to end itself.
            self._set(
                take,
                state=ERROR,
                error=load_error or "speech model failed to load",
            )
            return
        try:
            audio = self._capture(take)
        except Exception as exc:  # noqa: BLE001
            if self._current(take):
                self._set(take, state=ERROR, error=f"microphone failed: {exc}")
            return

        if not self._current(take):
            return
        if audio.size == 0:
            self._set(take, state=DONE, text="", seconds=0.0)
            return

        self._set(take, state=TRANSCRIBING, seconds=audio.size / SAMPLING_RATE)
        self._model_ready.wait()
        if not self._current(take):
            return
        try:
            text = self.transcribe(audio)
        except Exception as exc:  # noqa: BLE001
            if self._current(take):
                self._set(take, state=ERROR, error=f"transcription failed: {exc}")
            return
        if self._current(take):
            self._set(take, state=DONE, text=text)

    def _capture(self, take: _Take) -> np.ndarray:
        """Records until stopped, until silence, or until the cap. Never raises
        on reaching a limit, audio already spoken is audio the user owns."""
        silence_chunks = int(SILENCE_DURATION * SAMPLING_RATE / CHUNK_SIZE)
        lead_in_chunks = int(LEAD_IN * SAMPLING_RATE / CHUNK_SIZE)
        max_chunks = int(MAX_RECORDING * SAMPLING_RATE / CHUNK_SIZE)

        buffer: list[np.ndarray] = []
        # Bounded on purpose: the meter draws a window, and an hour-long take
        # must not grow a list the UI would then have to ship over IPC.
        levels: deque[float] = deque(maxlen=LEVEL_HISTORY)
        heard_speech = False
        silence_run = 0
        # Read once, at the start of the take. The take waited for the VAD
        # before opening the mic, so this is only None in tests, but the
        # check stays, because a take that somehow has no auto-stop must run
        # to the cap or the user's hand, never cut on a pause it cannot hear.
        vad = self._vad
        if vad is not None and self._vad_reset is not None:
            self._vad_reset()

        stream = self._open_stream()
        stream.start()
        try:
            while not take.stop.is_set():
                chunk, _ = stream.read(CHUNK_SIZE)
                chunk = np.asarray(chunk, dtype=np.float32).flatten()
                buffer.append(chunk)

                # Everything from the moment the shortcut was pressed is kept,
                # including the pauses. Chico buffered only what the VAD called
                # speech, which is right for fire-and-forget dictation and
                # wrong here: over minutes, a VAD that clips a quiet passage
                # deletes a sentence the user will not know is missing.
                if vad is not None:
                    if vad(chunk) > VAD_THRESHOLD:
                        heard_speech = True
                        silence_run = 0
                    else:
                        silence_run += 1

                    if heard_speech and silence_run > silence_chunks:
                        break
                    if not heard_speech and len(buffer) > lead_in_chunks:
                        return np.empty(0, dtype=np.float32)

                if len(buffer) >= max_chunks:
                    break

                # Plain RMS, unshaped. How loud this looks is a display
                # decision and it lives in the UI: speech RMS sits around
                # 0.02 to 0.08, so any curve applied here would be a meter
                # calibration baked into the wire, re-tunable only by
                # reinstalling the service.
                levels.append(float(np.sqrt(np.mean(chunk * chunk))))
                self._set(
                    take,
                    state=RECORDING if heard_speech else LISTENING,
                    seconds=len(buffer) * CHUNK_SIZE / SAMPLING_RATE,
                    levels=list(levels),
                )
        finally:
            try:
                stream.stop()
            finally:
                stream.close()

        if take.cancelled or not buffer:
            return np.empty(0, dtype=np.float32)
        return np.concatenate(buffer)

    # -- transcription -----------------------------------------------------

    def transcribe(self, audio: np.ndarray) -> str:
        segments, _ = self._model.transcribe(
            audio,
            language=LANGUAGE,
            task="transcribe",
            beam_size=1,
            best_of=1,
            # Whisper's temperature fallback, left on. Chico pinned this to 0.0
            # for speed, which is safe for one short phrase and not for ten
            # minutes: with no fallback a decode that degenerates into a repeat
            # loop has nothing to fall back to, and the loop lands in the
            # transcript. The extra passes only run on segments that trip the
            # compression-ratio and logprob thresholds, so a clean recording
            # pays nothing.
            temperature=[0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            # Long dictation is many windows; conditioning each on the last is
            # how one bad window poisons the rest.
            condition_on_previous_text=False,
            word_timestamps=False,
            vad_filter=False,
        )
        text = " ".join(segment.text.strip() for segment in segments).strip()
        if text.lower() in HALLUCINATIONS:
            return ""
        return text


class _ResamplingStream:
    """Wraps an `InputStream` captured at `native_rate` and linearly resamples
    every `read()` down to `target_rate`.

    VAD and Whisper are both fixed at `SAMPLING_RATE` (16kHz); the input
    hardware doesn't have to be. Some devices, real ALSA hardware, not the
    pulse/dmix virtual ones, only accept their own fixed rate and raise
    `PortAudioError: Invalid sample rate` (PaErrorCode -9997) if asked for
    anything else.
    ponytail: linear interpolation, not polyphase resampling, cheap, no new
    dependency, good enough for speech. Upgrade to scipy if transcription
    quality on non-16kHz hardware turns out to matter.
    """

    def __init__(self, stream, native_rate: int, target_rate: int):
        self._stream = stream
        self._ratio = native_rate / target_rate

    def start(self):
        self._stream.start()

    def stop(self):
        self._stream.stop()

    def close(self):
        self._stream.close()

    def read(self, frames):
        native_frames = max(1, round(frames * self._ratio))
        chunk, overflow = self._stream.read(native_frames)
        chunk = np.asarray(chunk, dtype=np.float32).flatten()
        resampled = np.interp(
            np.linspace(0, chunk.size - 1, frames), np.arange(chunk.size), chunk
        )
        return resampled.astype(np.float32), overflow


def _resolve_device() -> int | None:
    """`DEVICE` as an index, checked against the devices that exist right now.

    PortAudio numbers devices per process, from whatever ALSA reports at that
    moment, an index picked while a headset was plugged in names a different
    device once it is not, and the failure is `Not an input device: 'HDA
    NVidia: HDMI 3'`, about hardware the user never chose. Resolving by name
    and only ever among inputs means a stale selection says so instead.
    """
    import sounddevice as sd

    if DEVICE is None:
        return None
    for i, d in enumerate(sd.query_devices()):
        if d["max_input_channels"] > 0 and DEVICE in (i, d["name"]):
            return i
    raise RuntimeError(f"{DEVICE!r} is not a connected microphone, pick another in Settings")


def _open_microphone():
    import sounddevice as sd

    device = _resolve_device()
    try:
        return sd.InputStream(
            samplerate=SAMPLING_RATE,
            channels=1,
            dtype="float32",
            blocksize=CHUNK_SIZE,
            device=device,
        )
    except sd.PortAudioError:
        native_rate = int(sd.query_devices(device, "input")["default_samplerate"])
        native_stream = sd.InputStream(
            samplerate=native_rate,
            channels=1,
            dtype="float32",
            blocksize=round(CHUNK_SIZE * native_rate / SAMPLING_RATE),
            device=device,
        )
        return _ResamplingStream(native_stream, native_rate, SAMPLING_RATE)


def list_input_devices() -> list[dict]:
    """Every device sounddevice can record from, for the settings picker."""
    import sounddevice as sd

    default = sd.default.device[0]
    return [
        {"index": i, "name": d["name"], "default": i == default}
        for i, d in enumerate(sd.query_devices())
        if d["max_input_channels"] > 0
    ]


if __name__ == "__main__":
    # Smoke test by hand: talk, then stay quiet.
    t = VoiceTranscriber()
    print("loading model…")
    t._model_ready.wait()
    print("speak now")
    t.start()
    while t.status().state not in (DONE, ERROR):
        time.sleep(0.2)
    print(t.status())
