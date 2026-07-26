#!/usr/bin/env bash
set -e

echo "==> Configuring GitHub CLI repository..."
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

echo "==> Updating system packages..."
sudo apt update
sudo apt install -y git vim universal-ctags curl bash-completion gh tmux

echo "==> Managing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Ensure uv is available in the current script execution context
export PATH="$HOME/.local/bin:$PATH"

echo "==> Managing Python..."
uv python install

echo "==> Managing CLI tools..."
uv tool install ruff 2>/dev/null || true
uv tool install mdformat --with mdformat-gfm 2>/dev/null || true
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
