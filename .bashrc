# Set Vim as default editor
export EDITOR=vim
export VISUAL=vim

# Prepend the local bin directory so uv-managed tools load first
export PATH="$HOME/.local/bin:$PATH"

# Increase history capacity to preserve complex pipeline commands
export HISTSIZE=50000
export HISTFILESIZE=100000

# Append to history rather than overwriting and deduplicate entries
shopt -s histappend
export HISTCONTROL=ignoreboth:erasedups

# Bare Repository Management for dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Terminal title (User@Host)
export PS1="\[\033]0;\u@\h\007\]"               

# Minimal prompt
CYAN="\[\033[0;36m\]"
WHITE="\[\033[1;37m\]"
RESET="\[\033[0m\]"
PS1+="${CYAN}\w\n${WHITE}\$ ${RESET}"
