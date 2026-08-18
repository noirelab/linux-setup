#!/usr/bin/env bash
# Launcher for the dictation service. Maegor spawns this, not api.py directly.
#
# The one thing this does that Rust cannot do as cheaply is put the pip-installed
# CUDA libraries on the loader path. faster-whisper links cuBLAS and cuDNN at
# runtime and, without this, falls back to CPU or fails to load the model
# outright, with an error that names neither library.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

if [ ! -x .venv/bin/python ]; then
    echo "voice service is not installed, run services/voice/setup.sh" >&2
    exit 127
fi

CUDA_LIBS="$(.venv/bin/python - <<'PY' 2>/dev/null || true
import os
import nvidia.cublas, nvidia.cudnn
print(os.path.join(nvidia.cublas.__path__[0], "lib") + ":" + os.path.join(nvidia.cudnn.__path__[0], "lib"))
PY
)"
if [ -n "$CUDA_LIBS" ]; then
    export LD_LIBRARY_PATH="$CUDA_LIBS${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

exec .venv/bin/python api.py
