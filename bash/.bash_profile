#!/usr/bin/env bash
# ~/.bash_profile
# Managed in: dotfiles/bash/.bash_profile

# Load .bashrc for interactive shells
if [[ $- == *i* ]]; then
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    fi
fi

# =============================================================================
# SSH/GPG Agent (optional - uncomment if needed)
# =============================================================================

# Start SSH agent if not running
# if [ -z "$SSH_AUTH_SOCK" ]; then
#     eval "$(ssh-agent -s)"
#     ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
# fi
