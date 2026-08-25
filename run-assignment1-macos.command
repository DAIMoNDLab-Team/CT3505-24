#!/bin/bash
# CT3505-24 Assignment 1 launcher (macOS).
# Double-click this file to activate the "ct3505" conda environment and
# start Mercury for Assignment 1 - your browser will open automatically.
# Run install-macos.command first if you haven't already.

set -e
cd "$(dirname "$0")"
ENV_NAME="ct3505"

echo "CT3505-24 - Assignment 1"
echo "========================="

CONDA_EXE=""
if command -v conda >/dev/null 2>&1; then
    CONDA_EXE="$(command -v conda)"
else
    for c in "$HOME/miniconda3/bin/conda" "$HOME/opt/miniconda3/bin/conda" \
             "/opt/homebrew/Caskroom/miniconda/base/bin/conda" \
             "/usr/local/Caskroom/miniconda/base/bin/conda"; do
        if [[ -x "$c" ]]; then
            CONDA_EXE="$c"
            break
        fi
    done
fi

if [[ -z "$CONDA_EXE" ]]; then
    echo "Could not find conda. Please run install-macos.command first."
    read -p "Press Enter to close..."
    exit 1
fi

if ! "$CONDA_EXE" env list | grep -qE "^${ENV_NAME}[[:space:]]"; then
    echo "The '$ENV_NAME' conda environment was not found. Please run install-macos.command first."
    read -p "Press Enter to close..."
    exit 1
fi

echo "Starting Mercury for Assignment 1..."
echo "Your browser will open automatically. Close this window (or press Ctrl+C) to stop the server when you're done."
# Source conda.sh directly (conda's own recommended way to enable
# activation in a script) rather than conda init, which requires
# rc-file changes and a new shell.
CONDA_BASE="$("$CONDA_EXE" info --base)"
source "$CONDA_BASE/etc/profile.d/conda.sh"
conda activate "$ENV_NAME"
mercury run

read -p $'\nPress Enter to close this window...'
