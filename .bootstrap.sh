#!/usr/bin/env bash
# `set -e` — abort the whole script the moment any command exits non-zero.
# This makes failures loud and stops us from continuing in a half-broken state.
# Consequence: any command we EXPECT to sometimes fail must be explicitly guarded
# (with `if`, `|| true`, or `command -v`), otherwise it will kill the script.
set -e

echo "==> Configuring GitHub CLI repository..."
sudo mkdir -p -m 755 /etc/apt/keyrings
# `curl -fsSL`: -f fails on HTTP errors (so we don't pipe an error page into the
# keyring), -sS stays quiet but still shows real errors, -L follows redirects.
# If the download fails, `set -e` aborts here rather than writing a bad key.
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

echo "==> Configuring Databricks CLI repository..."
curl -fsSL https://databricks.github.io/databricks-cli-linux/gpg | sudo tee /etc/apt/keyrings/databricks.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/databricks.gpg
echo "deb [signed-by=/etc/apt/keyrings/databricks.gpg] https://databricks.github.io/databricks-cli-linux stable main" | sudo tee /etc/apt/sources.list.d/databricks.list > /dev/null

echo "==> Configuring HashiCorp (Terraform) repository..."
# HashiCorp ships an ASCII-armored key, so it must be run through `gpg --dearmor`
# (unlike the GitHub/Databricks binary keys that pipe straight into `tee`).
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
sudo chmod go+r /etc/apt/keyrings/hashicorp.gpg
# Codename resolved dynamically via lsb_release (assumed present on standard
# Ubuntu images), so the repo line tracks whatever release this runs on instead
# of being pinned to one version.
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

echo "==> Updating system packages..."
sudo apt update
sudo apt install -y git vim universal-ctags curl bash-completion gh tmux \
    bubblewrap databricks terraform

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
uv tool install omnigent
uv tool upgrade --all

# MCP fetch server (used by the omnigent agent's `reader` tool to turn a URL
# into clean markdown) is NOT installed here and does NOT run on Windows.
# omnigent launches it in WSL2 as a stdio child process via `uvx mcp-server-fetch`,
# which self-installs on first use through the uv already set up above — so no
# bootstrap install line is needed. It is a CPU-only HTTP/HTML->markdown process
# with no GPU need, so (unlike Ollama) it belongs WSL2-side with omnigent, not on
# Windows. Note: this is the Python reference server (runs via uvx); a JS-rendering
# fetch MCP would instead need Node/npm added to the apt install list above.

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
#
# Enable mirrored networking once on the Windows side, in %UserProfile%\.wslconfig:
#     [wsl2]
#     networkingMode=mirrored
# then restart WSL from an elevated PowerShell:  wsl --shutdown
# (Requires Windows 11 22H2+; leave Ollama on its default loopback bind.)
#
# OLLAMA TUNING (set these on the Windows side before starting the Ollama server;
# e.g. via `setx` then restart Ollama, or in its service environment):
#     OLLAMA_FLASH_ATTENTION=1     # enables the fused attention fast path
#     OLLAMA_KV_CACHE_TYPE=q8_0    # ~half the KV memory, near-lossless (NOT q4_0)
#     OLLAMA_NUM_PARALLEL=1        # serialize requests: one KV cache at a time, so
#                                  # multiple omnigent sub-agents share the single
#                                  # ~20GB model instance instead of each needing
#                                  # its own KV allocation (would blow 24GB budget).
# Note: sub-agents are separate API clients, NOT separate model instances — the
# 27B weights load once; only the per-conversation KV cache differs.
# If flash-attention misbehaves on the Vulkan/iGPU path, drop it and run f16 KV
# at 24K instead of q8_0 at 32K.
#
# Pull a model that fits ~24GB usable, e.g.:
#     ollama pull qwen3.8-27b         # dense, 24GB reference coder
#     ollama pull muse-glimmer:30b    # agentic, ~4-bit under 20GB
#
# With mirrored mode active, WSL2 reaches the Windows-hosted Ollama via localhost.
# Point omnigent at it with:
#     export OLLAMA_HOST="http://localhost:11434"
# (Add that line to your shell rc, or wire it into omnigent's own config.)

echo "==> Generating static bash completions..."
COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
mkdir -p "$COMPLETION_DIR"
# These are guarded with `command -v` (checks the binary exists on PATH) even
# though the installs above are now fatal-on-failure. The guard converts an
# unexpected "missing binary" case into a clear WARNING + a continued run, rather
# than a cryptic `set -e` abort right at the end of the bootstrap.
if command -v uv >/dev/null 2>&1; then
    uv generate-shell-completion bash > "$COMPLETION_DIR/uv"
else
    echo "   WARNING: uv not found on PATH — skipped uv completion generation."
fi
if command -v ruff >/dev/null 2>&1; then
    ruff generate-shell-completion bash > "$COMPLETION_DIR/ruff"
else
    echo "   WARNING: ruff not found on PATH — skipped ruff completion generation."
fi

echo "==> Configuring bare repository..."
# Raw `git` (not a .bashrc alias): aliases aren't expanded in non-interactive
# shell scripts, so we spell out --git-dir/--work-tree explicitly.
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" config --local status.showUntrackedFiles no

echo "==> Environment bootstrap complete."
