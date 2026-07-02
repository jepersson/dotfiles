#!/usr/bin/env bash
set -e

echo "==> Updating system packages..."
sudo apt update
sudo apt install -y git vim universal-ctags curl bash-completion

echo "==> Managing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Ensure uv is available in the current script execution context
export PATH="$HOME/.local/bin:$PATH"

echo "==> Managing Python..."
uv python install

echo "==> Managing CLI tools..."
uv tool install ruff 2>/dev/null || true
uv tool install mdformat 2>/dev/null || true
uv tool upgrade --all

echo "==> Generating static bash completions..."
COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
mkdir -p "$COMPLETION_DIR"
uv generate-shell-completion bash > "$COMPLETION_DIR/uv"
ruff generate-shell-completion bash > "$COMPLETION_DIR/ruff"

echo "==> Configuring bare repository..."
# Hide untracked files so your home directory isn't treated as a giant git repo
# Note: We use the raw git command here because aliases defined in .bashrc 
# are not expanded in non-interactive shell scripts.
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" config --local status.showUntrackedFiles no

echo "==> Environment bootstrap complete."
