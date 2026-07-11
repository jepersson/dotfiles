# Set Vim as the absolute default editor
export EDITOR=vim
export VISUAL=vim

# Prepend the local bin directory so uv-managed tools load first
export PATH="$HOME/.local/bin:$PATH"

# Shell History (The "Ctrl+R" Memory)
# Increase history capacity to preserve complex pipeline commands
export HISTSIZE=50000
export HISTFILESIZE=100000

# Append to history rather than overwriting (crucial for multiple shell sessions)
shopt -s histappend

export HISTCONTROL=ignoreboth:erasedups

# Bare Repository Management
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Alias to add charcters to ls for types
alias ls='ls -F'

# # The Prompt (PS1)
# Terminal title (User@Host)
export PS1="\[\033]0;\u@\h\007\]"               
# ANSI Color Definitions
CYAN="\[\033[0;36m\]"
WHITE="\[\033[1;37m\]"
RESET="\[\033[0m\]"

# Minimalist prompt
PS1="${CYAN}\W\n${WHITE}\$ ${RESET}"
