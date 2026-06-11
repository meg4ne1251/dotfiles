# ~/.bashrc - interactive shell configuration
# Managed by dotfiles. Machine-specific tweaks go in ~/.bashrc.local

# If not running interactively, don't do anything.
case $- in
  *i*) ;;
  *) return ;;
esac

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth:erasedups     # drop dups and lines starting with a space
HISTTIMEFORMAT='%F %T '              # record a timestamp per entry
shopt -s histappend                  # append to history, don't overwrite
shopt -s checkwinsize                # keep $LINES/$COLUMNS up to date
shopt -s cmdhist                     # store multi-line commands as one entry
# Flush each command to the history file as it is entered.
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-}"

# ---------------------------------------------------------------------------
# Prompt (with git branch)
# ---------------------------------------------------------------------------
parse_git_branch() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
  local branch
  branch="$(git symbolic-ref --short HEAD 2>/dev/null \
            || git rev-parse --short HEAD 2>/dev/null)"
  [[ -n "$branch" ]] && printf ' (%s)' "$branch"
}

# Single quotes so the command substitution is re-evaluated on every prompt.
PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[1;33m\]$(parse_git_branch)\[\e[0m\]\$ '

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------
for _dir in "$HOME/bin" "$HOME/.local/bin"; do
  case ":$PATH:" in
    *":$_dir:"*) ;;                  # already present
    *) PATH="$_dir:$PATH" ;;
  esac
done
unset _dir
export PATH

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
export EDITOR=vim
export VISUAL=vim
export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8
export PAGER=less
export LESS='-R'

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias ls='ls --color=auto'
alias l='ls -CF'
alias ll='ls -alhF'
alias la='ls -A'
alias lt='ls -altrhF'                # newest last (sort by time)

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias rm='rm -i'                     # prompt before removing
alias cp='cp -i'
alias mv='mv -i'

alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate --all'

# Use modern replacements when available (Debian/Ubuntu names: batcat, fdfind).
if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
  alias bat='batcat'
elif command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi
if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------
# cd into a directory and list its contents.
cdl() { cd "$@" && ll; }

# mkdir -p then cd into it.
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# Search running processes (ps + grep, without matching grep itself).
psg() { ps aux | grep -i -e "[${1:0:1}]${1:1}" -e 'USER.*PID'; }

# Show which process is listening on a port.
port() {
  if [[ -z "${1:-}" ]]; then
    echo "usage: port <number>" >&2
    return 1
  fi
  if command -v lsof >/dev/null 2>&1; then
    sudo lsof -i ":$1"
  else
    ss -tulpn 2>/dev/null | grep ":$1"
  fi
}

# Make a timestamped backup copy of one or more files.
bak() {
  local f
  for f in "$@"; do
    cp -a -- "$f" "${f}.$(date +%Y%m%d-%H%M%S).bak"
  done
}

# Serve the current directory over HTTP (default port 8000).
serve() {
  local port="${1:-8000}"
  python3 -m http.server "$port"
}

# ---------------------------------------------------------------------------
# Bash completion
# ---------------------------------------------------------------------------
if ! shopt -oq posix; then
  if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
  elif [[ -f /etc/bash_completion ]]; then
    . /etc/bash_completion
  fi
fi

# ---------------------------------------------------------------------------
# Machine-specific overrides (not tracked in the repo)
# ---------------------------------------------------------------------------
[[ -f ~/.bashrc.local ]] && . ~/.bashrc.local
