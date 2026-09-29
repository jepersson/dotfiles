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
# Codename hardcoded (Ubuntu 26.04 = plucky) so we don't depend on lsb-release
# being installed at this point. Update this one word if you run on another release.
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com plucky main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

echo "==> Updating system packages..."
sudo apt update
sudo apt install -y git vim universal-ctags curl bash-completion gh tmux \
    databricks terraform

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

echo "==> Managing Ollama (local models)..."
# Installs the ollama binary + (on systemd hosts) a background service on :11434.
# Models are pulled manually afterwards, e.g.:  ollama pull <model>
curl -fsSL https://ollama.com/install.sh | sh

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
