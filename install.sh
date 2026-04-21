#!/usr/bin/env bash
# Dotfiles Installation Script
# Repository: https://github.com/msavdert/dotfiles
# Author: msavdert
#
# This script bootstraps a new machine with mise + manual symlinks
# Usage: curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly DOTFILES_REPO="https://github.com/msavdert/dotfiles.git"
readonly DOTFILES_DIR="$HOME/.dotfiles"
readonly CONFIG_DIR="$HOME/.config"
readonly MISE_INSTALL_URL="https://mise.run"
readonly MISE_BIN="$HOME/.local/bin/mise"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_step() {
    echo -e "${BLUE}==>${NC} $*"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

check_requirements() {
    log_step "Checking system requirements"
    
    if ! is_linux && ! is_macos; then
        log_error "Unsupported operating system: $(uname -s)"
        exit 1
    fi
    
    local required_commands=("curl" "git")
    local missing=()
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        if is_linux; then
            log_warn "Missing commands: ${missing[*]}. Installing..."
            if command_exists apt-get; then
                sudo apt-get update -qq && sudo apt-get install -y -qq "${missing[@]}"
            else
                log_error "Cannot auto-install ${missing[*]}. Please install manually."
                exit 1
            fi
        else
            log_error "Missing commands: ${missing[*]}. Please install them first (e.g. via brew)."
            exit 1
        fi
    fi
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

clone_dotfiles() {
    log_step "Cloning dotfiles repository"
    
    if [ -d "$DOTFILES_DIR" ]; then
        log "Repository already exists at $DOTFILES_DIR"
        return 0
    fi
    
    log "Cloning $DOTFILES_REPO to $DOTFILES_DIR"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

setup_symlinks() {
    log_step "Setting up configuration symlinks"
    
    # Ensure config directories exist
    mkdir -p "$CONFIG_DIR/mise"
    mkdir -p "$CONFIG_DIR/nvim"
    mkdir -p "$CONFIG_DIR/zellij"

    # Define mappings: source -> target
    # Using an array of strings since associative arrays require Bash 4.0+
    # format: "source|target"
    local links=(
        "$DOTFILES_DIR/configs/.zshrc|$HOME/.zshrc"
        "$DOTFILES_DIR/configs/starship.toml|$CONFIG_DIR/starship.toml"
        "$DOTFILES_DIR/configs/nvim|$CONFIG_DIR/nvim"
        "$DOTFILES_DIR/configs/zellij|$CONFIG_DIR/zellij"
        "$DOTFILES_DIR/mise.toml|$CONFIG_DIR/mise/config.toml"
    )

    for link in "${links[@]}"; do
        local src="${link%%|*}"
        local dst="${link##*|}"
        
        if [ -e "$src" ]; then
            log "Linking $src -> $dst"
            # Remove destination if it exists (but isn't a symlink to source)
            if [ -e "$dst" ] || [ -L "$dst" ]; then
                rm -rf "$dst"
            fi
            ln -sf "$src" "$dst"
        else
            log_warn "Source file $src not found, skipping..."
        fi
    done
}

install_mise() {
    log_step "Installing mise"
    
    if command_exists mise; then
        log "mise is already installed: $(mise --version)"
        return 0
    fi
    
    if [ -f "$MISE_BIN" ]; then
         log "mise binary found at $MISE_BIN"
    else
        log "Downloading and installing mise"
        curl -fsSL "$MISE_INSTALL_URL" | sh
    fi

    # Ensure mise is in path for the rest of the script
    export PATH="$HOME/.local/bin:$PATH"
}

install_tools() {
    log_step "Installing tools from mise configuration"
    
    # Trust the dotfiles directory to avoid security prompts
    if command_exists mise; then
        log "Trusting $DOTFILES_DIR and global config"
        "$MISE_BIN" trust "$DOTFILES_DIR"
        "$MISE_BIN" trust "$CONFIG_DIR/mise/config.toml"
    fi

    # We linked mise.toml to ~/.config/mise/config.toml, so mise install will use it
    if "$MISE_BIN" install; then
        log "All tools installed successfully"
    else
        log_warn "Some tools failed to install. You may need to run 'mise install' manually."
    fi
}

print_summary() {
    echo ""
    echo "======================================================================"
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo "======================================================================"
    echo ""
    echo "Installed tools:"
    "$MISE_BIN" list
    echo ""
    echo "Quick Start Guide:"
    echo "  1. Activate ZSH:  exec zsh"
    echo "  2. Default Shell: chsh -s \$(which zsh)  (optional)"
    echo ""
    echo "Enjoy your new workspace!"
    echo "======================================================================"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    echo ""
    echo "======================================================================"
    echo "Dotfiles Installation Script"
    echo "Repository: $DOTFILES_REPO"
    echo "======================================================================"
    echo ""
    
    check_requirements
    clone_dotfiles
    setup_symlinks
    install_mise
    install_tools
    print_summary
}

main "$@"