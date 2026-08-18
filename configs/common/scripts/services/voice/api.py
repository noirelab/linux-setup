"""HTTP surface for the dictation service, over a Unix socket.

Every endpoint returns immediately, none of them waits for the microphone or
for Whisper. That is what lets the caller keep a short, honest read timeout: a
request that has not answered in five seconds is a broken service, not a person
who is still talking.

The socket path and the token both come from the parent process; there is no
default and no fallback, so the service cannot accidentally come up listening
without one.
"""

import logging
import os
import secrets

import uvicorn
from fastapi import Depends, FastAPI, Header, HTTPException, status
from pydantic import BaseModel

from transcriber import VoiceTranscriber, list_input_devices

logger = logging.getLogger(__name__)

API_TOKEN = os.environ.get("MAEGOR_VOICE_TOKEN")
API_SOCKET = os.environ.get("MAEGOR_VOICE_SOCKET")
if not API_TOKEN or not API_SOCKET:
    raise RuntimeError("MAEGOR_VOICE_TOKEN and MAEGOR_VOICE_SOCKET must be set")

app = FastAPI()
transcriber = VoiceTranscriber()


class StatusResponse(BaseModel):
    state: str
    seconds: float
    text: str
    error: str | None
    model_ready: bool
    device: str
    # Recent capture loudness, oldest first. Empty whenever nothing is being
    # recorded, which is what the UI reads to know it has nothing to draw.
    levels: list[float] = []


class InputDevice(BaseModel):
    index: int
    name: str
    default: bool


def require_token(x_maegor_token: str | None = Header(default=None)) -> None:
    if not x_maegor_token or not secrets.compare_digest(x_maegor_token, API_TOKEN):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")


def _respond(state) -> StatusResponse:
    return StatusResponse(**vars(state))


@app.get("/health", response_model=StatusResponse)
def health(_: None = Depends(require_token)):
    return _respond(transcriber.status())


@app.get("/status", response_model=StatusResponse)
def read_status(_: None = Depends(require_token)):
    return _respond(transcriber.status())


@app.get("/devices", response_model=list[InputDevice])
def devices(_: None = Depends(require_token)):
    return list_input_devices()


@app.post("/start", response_model=StatusResponse)
def start(_: None = Depends(require_token)):
    return _respond(transcriber.start())


@app.post("/stop", response_model=StatusResponse)
def stop(_: None = Depends(require_token)):
    return _respond(transcriber.stop())


@app.post("/cancel", response_model=StatusResponse)
def cancel(_: None = Depends(require_token)):
    return _respond(transcriber.cancel())


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    logger.info("Maegor voice service listening on %s", API_SOCKET)
    uvicorn.run(app, uds=API_SOCKET, log_level="warning")
