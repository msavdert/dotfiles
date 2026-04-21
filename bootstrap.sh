#!/usr/bin/env bash
# Dotfiles Installation Script
# Repository: https://github.com/msavdert/dotfiles
# Author: msavdert
#
# This script bootstraps a new machine with mise + manual symlinks
# Usage: curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash

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
    
    # Core requirements plus tools we expect from the infrastructure
    local required_commands=("curl" "git" "zsh" "ttyd")
    local missing=()
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing[*]}"
        log "Please ensure these are installed via your infrastructure (e.g., docker-compose or apt)."
        exit 1
    fi
    log "All system requirements met."
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

clone_dotfiles() {
    log_step "Cloning or updating dotfiles repository"
    
    if [ -d "$DOTFILES_DIR" ]; then
        log "Repository already exists at $DOTFILES_DIR, pulling updates"
        git -C "$DOTFILES_DIR" pull
        return 0
    fi
    
    log "Cloning $DOTFILES_REPO to $DOTFILES_DIR"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

setup_symlinks() {
    log_step "Calling setup-symlinks.sh"
    
    if [ -f "$DOTFILES_DIR/scripts/setup-symlinks.sh" ]; then
        chmod +x "$DOTFILES_DIR/scripts/setup-symlinks.sh"
        "$DOTFILES_DIR/scripts/setup-symlinks.sh"
    else
        log_error "Setup script not found at $DOTFILES_DIR/scripts/setup-symlinks.sh"
        exit 1
    fi
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
    echo "  - To refresh your current session:  exec zsh"
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
    install_mise
    
    # Trust the dotfiles and config before linking
    if command_exists mise; then
        log "Trusting $DOTFILES_DIR"
        "$MISE_BIN" trust "$DOTFILES_DIR"
    fi

    setup_symlinks
    install_tools
    print_summary
}

main "$@"