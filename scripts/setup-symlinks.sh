#!/usr/bin/env bash
# Dotfiles Symlink Setup Script
# This script creates symbolic links from the dotfiles repository to the home directory.
# It is designed to be idempotent and can be run safely multiple times.

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$SCRIPT_DIR")}"
readonly CONFIG_DIR="${CONFIG_DIR:-$HOME/.config}"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_step() { echo -e "${BLUE}==>${NC} $*"; }

# Timestamp for unique backups
readonly TIMESTAMP=$(date +%Y%m%d%H%M%S)

setup_symlinks() {
    log_step "Setting up configuration symlinks"
    
    # Ensure config directories exist
    mkdir -p "$CONFIG_DIR/mise"
    mkdir -p "$CONFIG_DIR/nvim"
    mkdir -p "$CONFIG_DIR/zellij"
    mkdir -p "$HOME/.ssh/sockets"

    # Define mappings: source|target
    local links=(
        "$DOTFILES_DIR/configs/.zshrc|$HOME/.zshrc"
        "$DOTFILES_DIR/configs/.gitconfig|$HOME/.gitconfig"
        "$DOTFILES_DIR/configs/starship.toml|$CONFIG_DIR/starship.toml"
        "$DOTFILES_DIR/configs/nvim|$CONFIG_DIR/nvim"
        "$DOTFILES_DIR/configs/zellij|$CONFIG_DIR/zellij"
        "$DOTFILES_DIR/configs/ssh/config|$HOME/.ssh/config"
        "$DOTFILES_DIR/mise.toml|$CONFIG_DIR/mise/config.toml"
    )

    for link in "${links[@]}"; do
        local src="${link%%|*}"
        local dst="${link##*|}"
        
        if [ -e "$src" ] || [ -L "$src" ]; then
            # If destination exists
            if [ -e "$dst" ] || [ -L "$dst" ]; then
                # If it's already a symlink pointing to the right place, skip
                if [ -L "$dst" ] && [ "$(readlink "$dst")" == "$src" ]; then
                    log "Skipping $dst (already linked to $src)"
                    continue
                fi

                # If it's a real file/dir or a wrong symlink, back it up
                local backup="${dst}.${TIMESTAMP}.bak"
                log_warn "Destination $dst exists. Backing up to $backup"
                mv "$dst" "$backup"
            fi

            log "Linking $src -> $dst"
            ln -sf "$src" "$dst"
        else
            log_warn "Source file $src not found, skipping..."
        fi
    done
}

# Run the setup
setup_symlinks
