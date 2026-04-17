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

alias ll='ls -lAh'
alias la='ls -A'
alias lt='ls -lAht'
alias l='ls -CF'

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
alias du='du -h'

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
