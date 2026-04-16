#!/usr/bin/env bash
# ~/.bashrc
# Managed in: dotfiles/bash/.bashrc

# =============================================================================
# Shell Options
# =============================================================================

# History
shopt -s histappend
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
HISTTIMEFORMAT="%F %T "

# Directory navigation
shopt -s cdspell
shopt -s checkwinsize
shopt -s globstar
shopt -s nocaseglob

# =============================================================================
# Environment
# =============================================================================

# XDG Base Directory
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Editors
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"
export PAGER="${PAGER:-less}"

# Less colors
export LESS='-R'
export LESS_TERMCAP_mb=$'\033[1;31m'
export LESS_TERMCAP_md=$'\033[1;36m'
export LESS_TERMCAP_me=$'\033[0m'
export LESS_TERMCAP_se=$'\033[0m'
export LESS_TERMCAP_so=$'\033[1;44;33m'
export LESS_TERMCAP_ue=$'\033[0m'
export LESS_TERMCAP_us=$'\033[1;32m'

# =============================================================================
# Path
# =============================================================================

# Local bin with deduplication
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# =============================================================================
# Bash Completion
# =============================================================================

# Enable bash-completion if available
if command -v brew &>/dev/null && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    source "$(brew --prefix)/etc/bash_completion"
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
elif [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
fi

# =============================================================================
# Prompt (Simplified - no external dependencies)
# =============================================================================

# Git branch in prompt (fast)
git_branch() {
    local branch
    if branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null); then
        if [[ "$branch" != "HEAD" ]]; then
            echo " ($branch)"
        fi
    fi
}

# Exit status
exit_status() {
    local ex=$?
    if [ $ex -ne 0 ]; then
        echo " [$ex]"
    fi
}

# Colors
CYAN='\[\033[01;36m\]'
GREEN='\[\033[01;32m\]'
BLUE='\[\033[01;34m\]'
RED='\[\033[01;31m\]'
RESET='\[\033[00m\]'

PS1="${GREEN}\u@\h${RESET}:${CYAN}\w${RESET}\$(git_branch)${RED}\$(exit_status)${RESET}\$ "

# =============================================================================
# Aliases
# =============================================================================

if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# =============================================================================
# Git Identity Check
# =============================================================================

if [ -z "${GIT_AUTHOR_NAME:-}" ] || [ -z "${GIT_AUTHOR_EMAIL:-}" ]; then
    if [ -t 1 ]; then  # Only warn if interactive
        echo -e "\033[1;33m[bashrc]\033[0m Git identity not set. Run:"
        echo "  export GIT_AUTHOR_NAME=\"Your Name\""
        echo "  export GIT_AUTHOR_EMAIL=\"you@example.com\""
    fi
fi
