#!/usr/bin/env bash
# scripts/13-python-dojo.sh
# Provision a repeatable Dojo conda environment for Python, AI, and ML workflows.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ENV_NAME="dojo"
CONDA_ROOT="$HOME/.local/miniconda3"
CONDA_BIN="$CONDA_ROOT/bin/conda"
ENVS_DIR="$CONDA_ROOT/envs"
MANIFEST_DIR="$HOME/.config/dotfiles/envs"
MANIFEST_FILE="$MANIFEST_DIR/dojo-requirements.txt"

# Core packages installed via conda (benefit from binary builds)
CONDA_PACKAGES=(
    "python=3.11"
    numpy
    pandas
    scipy
    matplotlib
    seaborn
    scikit-learn
    jupyterlab
    notebook
    ipykernel
)

PYTORCH_CHANNELS=(
    "pytorch"
    "nvidia"
)

PYTORCH_PACKAGES=(
    torch
    torchvision
    torchaudio
)

# Packages installed via pip (more flexible versioning, avoids solver conflicts)
PIP_PACKAGES=(
    black
    flake8
    mypy
    poetry
    fastapi
    pydantic
    "pydantic-settings"
    uvicorn
    openai
    langchain
    langchain-community
    langsmith
    "jupyterlab-lsp"
    "python-lsp-server[all]"
    rich
    httpx
    aiohttp
    "rich-argparse"
)

section_header "Provisioning Dojo Conda Environment"

if [ ! -x "$CONDA_BIN" ]; then
    err "Conda not found at $CONDA_BIN. Run scripts/08-data-science.sh first."
    exit 1
fi

eval "$("$CONDA_BIN" shell.bash hook)"

if "$CONDA_BIN" env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    info "Conda environment '$ENV_NAME' already exists"
else
    step "Creating conda environment '$ENV_NAME'"
    "$CONDA_BIN" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main 2>/dev/null || true
    "$CONDA_BIN" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r 2>/dev/null || true
    "$CONDA_BIN" create -y -n "$ENV_NAME" "${CONDA_PACKAGES[@]}"
fi

step "Activating '$ENV_NAME'"
# shellcheck disable=SC1091
source "$CONDA_ROOT/bin/activate" "$ENV_NAME"

step "Adding additional channels for PyTorch"
for channel in "${PYTORCH_CHANNELS[@]}"; do
    "$CONDA_BIN" config --env --add channels "$channel" 2>/dev/null || true
done

step "Installing PyTorch stack"
"$CONDA_BIN" install -y "${PYTORCH_PACKAGES[@]}"

step "Upgrading pip and installing pip packages"
pip install --upgrade pip setuptools wheel
pip install "${PIP_PACKAGES[@]}"

step "Registering IPython kernel"
python -m ipykernel install --user --name "$ENV_NAME" --display-name "Dojo (Python)"

step "Exporting pip manifest"
mkdir -p "$MANIFEST_DIR"
pip freeze > "$MANIFEST_FILE"
info "Exported pip freeze to $MANIFEST_FILE"

script_complete "Dojo Python environment setup"
