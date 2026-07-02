# Set Vim as the absolute default editor
export EDITOR=vim
export VISUAL=vim

# Prepend the local bin directory so uv-managed tools load first
export PATH="$HOME/.local/bin:$PATH"


# # Shell History (The "Ctrl+R" Memory)
# Increase history capacity to preserve complex pipeline commands
export HISTSIZE=50000
export HISTFILESIZE=100000

# Append to history rather than overwriting (crucial for multiple shell sessions)
shopt -s histappend


# # Bare Repository Management
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'


# # The Prompt (PS1)
# ANSI color definitions
CYAN="\[\033[0;36m\]"
WHITE="\[\033[1;37m\]"
RESET="\[\033[0m\]"

# Terminal title (User@Host)
export PS1="\[\033]0;\u@\h\007\]"               
# Working directory (Cyan)
export PS1="${PS1}${CYAN}\w${RESET}"            
# Newline and input prompt (White)
export PS1="${PS1}${WHITE}\n$ ${RESET}"

