#!/usr/bin/env bash
# ~/.bash_aliases
# Managed in: dotfiles/bash/.bash_aliases

# =============================================================================
# Navigation
# =============================================================================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# =============================================================================
# Files
# =============================================================================

# Use eza if available for better ls
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lAh --icons --group-directories-first'
    alias la='eza -A --icons --group-directories-first'
    alias lt='eza -lAht --icons --group-directories-first'
    alias l='eza -CF --icons --group-directories-first'
    alias tree='eza --tree --icons'
else
    alias ll='ls -lAh'
    alias la='ls -A'
    alias lt='ls -lAht'
    alias l='ls -CF'
fi

# Safe rm/cp/mv
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Create directories
alias mkdir='mkdir -pv'

# =============================================================================
# Git
# =============================================================================

alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gst='git stash'
alias gstp='git stash pop'
alias gm='git merge'

# =============================================================================
# Docker
# =============================================================================

alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dcrestart='docker compose restart'

# =============================================================================
# System
# =============================================================================

alias c='clear'
alias cls='clear'
alias reload='source ~/.bashrc'

# Disk usage
alias df='df -h'
if command -v dust >/dev/null 2>&1; then
    alias du='dust'
else
    alias du='du -h'
fi

# Modern tools replacements
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --plain'
    alias catp='bat' # With paging and line numbers
fi

if command -v btm >/dev/null 2>&1; then
    alias top='btm'
fi

if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

if command -v lazygit >/dev/null 2>&1; then
    alias lg='lazygit'
fi

if command -v yazi >/dev/null 2>&1; then
    alias y='yazi'
fi

if command -v yq >/dev/null 2>&1; then
    alias query='yq'
fi

# Direnv (automatic environment loading)
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# =============================================================================
# Network
# =============================================================================

alias myip='curl -s http://ipecho.net/plain; echo'
alias localip="ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1"

# =============================================================================
# Zellij (Terminal Multiplexer)
# =============================================================================

alias z='zellij'
alias zl='zellij list-sessions'
alias za='zellij attach'
alias zk='zellij kill-session'

# 1Password (via op CLI)
# Use 'op run -- <command>' to inject secrets from references (op://...)

# Neovim
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# =============================================================================
# Modern Tool Initializations
# =============================================================================

# Zoxide (smarter cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# Starship (modern prompt)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# FZF (fuzzy finder)
if [ -f ~/.fzf.bash ]; then
    source ~/.fzf.bash
elif command -v fzf >/dev/null 2>&1; then
    # Basic fzf integration if not using the install script's source
    eval "$(fzf --bash)"
fi
