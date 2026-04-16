#!/usr/bin/env bash
# Symlink creation script (No-Sudo)
# Creates symlinks from home directory to dotfiles

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; }

# Portable way to get absolute path without realpath/readlink -f
get_abs_path() {
    local path="$1"
    if [[ "$path" == /* ]]; then
        echo "$path"
    else
        echo "$PWD/$path" | sed 's#/\./#/#g; s#/[^/]*/\.\./#/#g' # Simple normalization
    fi
}

# Create a symlink, backing up existing file if it exists
link_file() {
    local src="$1"
    local dest="$2"
    local description="${3:-"$dest"}"

    # Resolve src to absolute path
    # Using a simpler but effective way for dotfiles context
    if [[ "$src" != /* ]]; then
        src="$(cd "$(dirname "$src")" && pwd)/$(basename "$src")"
    fi

    # Check if destination already exists
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        # If it's already a symlink pointing to our file, skip
        local current_link
        current_link=$(readlink "$dest" || echo "")
        
        # Resolve current_link to absolute for comparison if it's relative
        if [[ -n "$current_link" && "$current_link" != /* ]]; then
             current_link="$(cd "$(dirname "$dest")" && pwd)/$current_link"
        fi

        if [ "$current_link" == "$src" ]; then
            log_skip "$description (already linked)"
            return 0
        fi

        # Backup existing file
        local backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        log "Backing up existing $description to $backup"
        mv "$dest" "$backup"
    fi

    # Create parent directory if needed
    local parent_dir
    parent_dir="$(dirname "$dest")"
    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir"
    fi

    # Create symlink
    ln -sf "$src" "$dest"
    log "Linked: $description"
}

# Main
# Bash configs
link_file "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
link_file "$DOTFILES_DIR/bash/.bash_aliases" "$HOME/.bash_aliases"
link_file "$DOTFILES_DIR/bash/.bash_profile" "$HOME/.bash_profile"

# Git config
link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Zellij config
link_file "$DOTFILES_DIR/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"

# SSH config (only if source exists)
if [ -f "$DOTFILES_DIR/ssh/config" ]; then
    link_file "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config" "SSH config"
    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
fi
