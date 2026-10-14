#!/usr/bin/env bash
# `set -e` — abort the whole script the moment any command exits non-zero.
# This makes failures loud and stops us from continuing in a half-broken state.
# Consequence: any command we EXPECT to sometimes fail must be explicitly guarded
# (with `if`, `|| true`, or `command -v`), otherwise it will kill the script.
set -e

echo "==> Configuring GitHub CLI repository..."
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& sudo mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \

echo "==> Configuring HashiCorp (Terraform) repository..."
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

echo "==> Updating system packages..."
sudo apt update
sudo apt install -y git vim universal-ctags curl bash-completion gh tmux terraform unzip

echo "==> Installing Databricks CLI..."
# Always reinstall the Databricks CLI
sudo rm '/usr/local/bin/databricks'
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sudo sh

echo "==> Managing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# The uv installer drops binaries in ~/.local/bin. That dir isn't necessarily on
# PATH in this non-interactive shell yet, so we prepend it now — otherwise the
# `uv` calls below would fail with "command not found" and `set -e` would abort.
export PATH="$HOME/.local/bin:$PATH"

echo "==> Managing Python..."
uv python install

echo "==> Managing CLI tools..."
# These installs are intentionally UNGUARDED: no `|| true`, no `2>/dev/null`.
# Under `set -e` that means if any install fails, the script stops immediately at
# the offending line with the tool's real error output — instead of silently
# swallowing the failure and only surfacing it later when the binary is missing.
uv tool install ruff
uv tool install mdformat --with mdformat-gfm
uv tool install --force --python python3.12 --with pip aider-chat@latest
uv tool upgrade --all

# NOTE: Ollama is intentionally NOT installed inside WSL2.
# AMD iGPUs (e.g. Radeon 860M, RDNA 3.5 / gfx1150) do not get GPU passthrough
# into WSL2, so an in-WSL Ollama would fall back to slow CPU-only inference.
# Instead, install Ollama natively on Windows (Vulkan backend) and point
# omnigent at it over the WSL2 -> Windows network bridge.
#
# NETWORKING: use WSL2 "mirrored" mode rather than binding Ollama to 0.0.0.0.
# Ollama has no authentication, so binding to 0.0.0.0 would expose the model
# server to the whole LAN. Mirrored mode lets WSL2 reach Windows services over
# localhost while Ollama keeps its default, safe 127.0.0.1:11434 bind.

echo "==> Generating static bash completions..."
COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
mkdir -p "$COMPLETION_DIR"
uv generate-shell-completion bash > "$COMPLETION_DIR/uv"
ruff generate-shell-completion bash > "$COMPLETION_DIR/ruff"

echo "==> Configuring bare repository..."
# Raw `git` (not a .bashrc alias): aliases aren't expanded in non-interactive
# shell scripts, so we spell out --git-dir/--work-tree explicitly.
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" config --local status.showUntrackedFiles no

echo "==> Environment bootstrap complete."
