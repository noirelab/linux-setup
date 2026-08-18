#!/usr/bin/env bash
# Creates the virtualenv the dictation service runs in.
#
# Kept out of the app deliberately: this pulls torch and a CUDA runtime, which
# is a gigabyte-scale install and a thing a user should choose, not discover
# because they pressed a shortcut once.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt

echo
echo "Voice service ready. The Whisper model downloads on first use."
