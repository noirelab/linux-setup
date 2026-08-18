"""Runs without torch, without faster-whisper and without a microphone.

The three things worth proving are the three that used to be wrong: a recording
longer than any client timeout still completes, reaching the hard cap keeps the
audio instead of raising, and an explicit stop ends a take the VAD would have
let run.

    python3 services/voice/test_transcriber.py
"""

import sys
import threading
import time
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))

import transcriber as tr  # noqa: E402
from transcriber import CHUNK_SIZE, DONE, ERROR, SAMPLING_RATE, VoiceTranscriber  # noqa: E402


class FakeStream:
    """A microphone that never runs out. `loud` decides what the VAD sees."""

    def __init__(self, loud=lambda n: True):
        self.loud = loud
        self.reads = 0
        self.closed = False

    def start(self):
        pass

    def read(self, size):
        self.reads += 1
        value = 1.0 if self.loud(self.reads) else 0.0
        return np.full(size, value, dtype=np.float32), None

    def stop(self):
        pass

    def close(self):
        self.closed = True


class FakeSegment:
    def __init__(self, text):
        self.text = text


class FakeModel:
    def __init__(self, text="olá mundo"):
        self.text = text
        self.samples = None
        self.options = None

    def transcribe(self, audio, **options):
        self.samples = audio.size
        self.options = options
        return iter([FakeSegment(f" {self.text} ")]), None


def build(stream, model=None, vad=True):
    t = VoiceTranscriber(open_stream=lambda: stream, load_models=False)
    t._model = model or FakeModel()
    if vad:
        # Silero's contract: one chunk in, one speech probability out.
        t._vad = lambda chunk: float(chunk[0])
        t._vad_reset = lambda: None
        t._vad_ready.set()
    t._model_ready.set()
    return t


def wait_for(t, state, timeout=5.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if t.status().state == state:
            return t.status()
        time.sleep(0.01)
    raise AssertionError(f"stuck in {t.status().state}, wanted {state}")


def test_silence_ends_a_take():
    stream = FakeStream(loud=lambda n: n <= 40)
    t = build(stream)
    t.start()
    status = wait_for(t, DONE)
    assert status.text == "olá mundo", status
    assert stream.closed, "the microphone must be released"


def test_silence_stops_a_take_while_the_model_is_still_loading():
    """The first take after launch starts while Whisper is downloading. The
    auto-stop must not wait for it: capture ends on silence, transcription
    waits for the model."""
    stream = FakeStream(loud=lambda n: n <= 40)
    t = build(stream)
    t._model_ready.clear()  # Whisper has not finished loading
    t.start()
    assert wait_for(t, "transcribing").state == "transcribing", \
        "capture must end on silence alone, with no model"
    t._model_ready.set()
    assert wait_for(t, DONE).text == "olá mundo"


def test_explicit_stop_ends_a_take_the_vad_would_not():
    stream = FakeStream(loud=lambda n: True)  # never falls silent
    t = build(stream)
    t.start()
    wait_for(t, "recording")
    t.stop()
    assert wait_for(t, DONE).text == "olá mundo"


def test_recording_outlives_any_client_timeout():
    """The regression this port exists for.

    Chico coupled record and transcribe into one HTTP call with a 25s read
    timeout, so a recording longer than that failed no matter how well the
    engine worked. Here a take is bounded only by the cap, and 60 simulated
    seconds, beyond that old timeout, still reaches DONE with the audio
    intact.
    """
    wanted = int(60 * SAMPLING_RATE / CHUNK_SIZE)
    stream = FakeStream(loud=lambda n: n <= wanted)
    model = FakeModel()
    t = build(stream, model)
    t.start()
    status = wait_for(t, DONE, timeout=30.0)
    assert status.seconds > 25.0, status.seconds
    assert model.samples >= wanted * CHUNK_SIZE, model.samples


def test_hitting_the_cap_transcribes_instead_of_discarding():
    original = tr.MAX_RECORDING
    tr.MAX_RECORDING = 0.5
    try:
        stream = FakeStream(loud=lambda n: True)
        model = FakeModel()
        t = build(stream, model)
        t.start()
        status = wait_for(t, DONE)
        assert status.text == "olá mundo", "audio at the cap must survive"
        assert model.samples > 0
    finally:
        tr.MAX_RECORDING = original


def test_cancel_discards_and_returns_to_idle():
    stream = FakeStream(loud=lambda n: True)
    model = FakeModel()
    t = build(stream, model)
    t.start()
    wait_for(t, "recording")
    t.cancel()
    time.sleep(0.3)
    assert t.status().state == "idle", t.status()
    assert model.samples is None, "cancelled audio must never reach Whisper"


def test_temperature_fallback_stays_on_for_long_audio():
    stream = FakeStream(loud=lambda n: n <= 20)
    model = FakeModel()
    t = build(stream, model)
    t.start()
    wait_for(t, DONE)
    assert model.options["temperature"] == [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
    assert model.options["condition_on_previous_text"] is False


def test_silence_only_take_returns_empty_without_calling_whisper():
    original = tr.LEAD_IN
    tr.LEAD_IN = 0.5
    try:
        stream = FakeStream(loud=lambda n: False)
        model = FakeModel()
        t = build(stream, model)
        t.start()
        status = wait_for(t, DONE)
        assert status.text == ""
        assert model.samples is None
    finally:
        tr.LEAD_IN = original


def test_take_waits_for_the_vad_before_opening_the_mic():
    """The regression this file exists for, second edition.

    A take started while the VAD was still loading read `vad` once, got None,
    and then no silence and no lead-in could ever end it, the first take
    after launch recorded to the cap or the user's hand. The mic must stay
    closed until the auto-stop exists.
    """
    stream = FakeStream(loud=lambda n: n <= 40)
    t = VoiceTranscriber(open_stream=lambda: stream, load_models=False)
    t._model = FakeModel()
    t.start()
    time.sleep(0.2)
    assert stream.reads == 0, "the mic must stay closed until the VAD exists"
    t._vad = lambda chunk: float(chunk[0])
    t._vad_reset = lambda: None
    t._vad_ready.set()
    t._model_ready.set()
    status = wait_for(t, DONE)
    assert status.text == "olá mundo"
    assert stream.closed


def test_stop_while_waiting_for_the_vad_ends_empty_without_the_mic():
    stream = FakeStream(loud=lambda n: True)
    t = VoiceTranscriber(open_stream=lambda: stream, load_models=False)
    t._model = FakeModel()
    t.start()
    t.stop()  # the user changes their mind before the models land
    t._vad_ready.set()  # whatever the load does, the wait must not hang
    status = wait_for(t, DONE)
    assert status.text == ""
    assert stream.reads == 0, "a mic that never opened must not be read"


def test_failed_model_load_ends_a_waiting_take_with_the_error():
    stream = FakeStream(loud=lambda n: True)
    t = VoiceTranscriber(open_stream=lambda: stream, load_models=False)
    t._model = FakeModel()
    t.start()
    with t._lock:
        t._status.error = "speech model failed to load: boom"
    t._vad_ready.set()  # the load failed; no VAD is ever published
    status = wait_for(t, ERROR)
    assert "boom" in status.error, status
    assert stream.reads == 0, "no auto-stop means no microphone"


def test_hallucination_filter_drops_silence_boilerplate():
    stream = FakeStream(loud=lambda n: n <= 20)
    t = build(stream, FakeModel("Obrigado."))
    t.start()
    assert wait_for(t, DONE).text == ""


def test_hallucination_filter_drops_noise_boilerplate():
    """Whisper turns a loud background into a phrase, seen on a fan-and-
    keyboard room with the fallback passes: 'Entertain us' with nobody in
    earshot. Same exact-match filter, same whole-transcript drop."""
    stream = FakeStream(loud=lambda n: n <= 20)
    t = build(stream, FakeModel("Entertain us."))
    t.start()
    assert wait_for(t, DONE).text == ""


def test_start_is_idempotent_while_a_take_is_live():
    stream = FakeStream(loud=lambda n: True)
    t = build(stream)
    t.start()
    wait_for(t, "recording")
    before = threading.active_count()
    t.start()
    assert threading.active_count() == before, "a second start must not open a second mic"
    t.cancel()


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")
