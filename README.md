# Dotfiles

A terminal-native configuration focused on execution speed, zero plugin dependencies, and keyboard navigation using standard POSIX utilities.

## Principles

- **Vanilla Native First:** No plugin managers or LSP clients. Built-in hooks (`makeprg`, `formatprg`, `wildmenu`, `ctags`) drive linting, formatting, and navigation.
- **Bare Repository Pattern:** Uses a Git bare repository mapped to `$HOME`. Keeps the home directory clean without symlinks, Stow, or custom managers.
- **Defensive Defaults:** Prevents accidental commits with missing credentials via `useConfigOnly = true`.

## Architecture Overview

| Component | Strategy | Key Behaviors |
| :--- | :--- | :--- |
| **Vim** | Plugin-free | `ruff` and `mdformat` bound to `makeprg` and `formatprg`. Native autocomplete via `wildmenu` with popup menu (`pum`). |
| **Tmux** | Minimal UI | Top status bar. Heavy pane borders in Cyan (active) and Dark Grey (inactive). |
| **Git** | Bare Repo + Linear | Rebase on pull enabled (`pull.rebase = true`). Blocks commits without local user config (`useConfigOnly = true`). |
| **Tooling** | Isolated Global Tools | `uv` manages Python versions and global CLI tools (`ruff`, `mdformat`, `gh`). |

## Provisioning

Setting up a fresh machine requires a three-step sequence: cloning the bare repository, checking out the files into `$HOME`, and executing `.bootstrap.sh`.

### 1. Clone the Bare Repository

Clone the repository into a hidden `.dotfiles` directory in `$HOME`:

git clone --bare https://github.com/jepersson/dotfiles.git $HOME/.dotfiles

### 2. Checkout Configurations

Checkout the tracked configuration files into `$HOME`:

git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout

Note: If existing system default files cause a collision, back up or remove the conflicting files and rerun the checkout command.

### 3. Run the Bootstrap Script

Run the provisioning script to install system packages via `apt`, set up `uv`, install isolated CLI tools, and generate static completions:

bash $HOME/.bootstrap.sh

Restart the shell or source `.bashrc`:

source ~/.bashrc

### 4. Configure Local Git Identity

Because `useConfigOnly = true` is set globally, set your name and email locally inside any repository before committing:

git config user.name "Your Name"
git config user.email "your.email@example.com"

## Management & Workflow

Manage tracked dotfiles using the `dotfiles` alias defined in `.bashrc`:

# Check status of tracked files

dotfiles status

# Add and commit changes

dotfiles add .vimrc
dotfiles commit -m "Update Vim settings"
dotfiles push

The bootstrap script sets `status.showUntrackedFiles no` locally for the bare repo, ensuring `dotfiles status` ignores untracked files in `$HOME`.

To inspect untracked files intentionally, pass `-u`:

dotfiles status -u

## Extending Configuration

### Adding a Linter or Formatter

To add support for a new language in Vim using native hooks:

1. Install the CLI tool via `uv`:

   uv tool install <tool-name>

1. Register the tool in `~/.vimrc`:

   augroup LanguageNativeSetup
   autocmd!
   " Set :make command for linting
   autocmd FileType <lang> setlocal makeprg=<tool>\\ %
   autocmd FileType <lang> setlocal errorformat=...

   ```
   " Set 'gq' operator for formatting
   autocmd FileType <lang> setlocal formatprg=<tool>\ -
   ```

   augroup END
