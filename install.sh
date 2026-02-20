#!/usr/bin/env bash
# Dotfiles Installation Script
# Repository: https://github.com/msavdert/dotfiles
# Author: msavdert
#
# This script bootstraps a new machine with mise + chezmoi
# Usage: curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
#
# Design principles:
# - Idempotent: Safe to run multiple times
# - Minimal: Only install mise and chezmoi, let them handle the rest
# - Clean: No hardcoded paths, no temp files

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly DOTFILES_REPO="https://github.com/msavdert/dotfiles.git"
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
    
    # Check OS
    if ! is_linux && ! is_macos; then
        log_error "Unsupported operating system: $(uname -s)"
        exit 1
    fi
    
    # Check for required commands
    local required_commands=("curl" "git")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            log_error "Required command not found: $cmd"
            log_error "Please install $cmd and try again"
            exit 1
        fi
    done
    
    log "System requirements met: $(uname -s) $(uname -m)"
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

install_mise() {
    log_step "Installing mise"
    
    if [ -f "$MISE_BIN" ]; then
        log "mise is already installed: $("$MISE_BIN" --version)"
        return 0
    fi
    
    log "Downloading and installing mise"
    if curl -fsSL "$MISE_INSTALL_URL" | sh; then
        log "mise installed successfully: $("$MISE_BIN" --version)"
    else
        log_error "Failed to install mise"
        exit 1
    fi
}

install_chezmoi() {
    log_step "Installing chezmoi with mise"
    
    # Check if chezmoi is already installed
    local CHEZMOI_BIN
    CHEZMOI_BIN="$("$MISE_BIN" which chezmoi 2>/dev/null || echo "")"
    
    if [ -n "$CHEZMOI_BIN" ] && [ -x "$CHEZMOI_BIN" ]; then
        log "chezmoi is already installed: $("$CHEZMOI_BIN" --version | head -n1)"
        return 0
    fi
    
    log "Installing chezmoi via mise"
    if "$MISE_BIN" use -g chezmoi@latest; then
        CHEZMOI_BIN="$("$MISE_BIN" which chezmoi)"
        log "chezmoi installed successfully: $("$CHEZMOI_BIN" --version | head -n1)"
    else
        log_error "Failed to install chezmoi"
        exit 1
    fi
}

setup_dotfiles() {
    log_step "Setting up dotfiles with chezmoi"
    
    local CHEZMOI_BIN
    CHEZMOI_BIN="$("$MISE_BIN" which chezmoi 2>/dev/null || echo "")"
    
    if [ -z "$CHEZMOI_BIN" ]; then
        log_error "chezmoi not found after installation"
        exit 1
    fi
    
    # Initialize chezmoi with dotfiles repo
    log "Initializing chezmoi with $DOTFILES_REPO"
    if "$CHEZMOI_BIN" init --apply "$DOTFILES_REPO"; then
        log "Dotfiles initialized and applied successfully"
    else
        log_error "Failed to initialize dotfiles"
        exit 1
    fi
}

install_tools() {
    log_step "Installing tools from mise configuration"
    
    # mise config is now managed by chezmoi at ~/.config/mise/config.toml
    log "Installing tools defined in ~/.config/mise/config.toml"
    
    if "$MISE_BIN" install; then
        log "All tools installed successfully"
    else
        log_warn "Some tools failed to install"
        log_warn "Run 'mise install' manually to retry"
    fi
    
    # Show installed tools
    log "Installed tools:"
    "$MISE_BIN" list
}

print_summary() {
    echo ""
    echo "======================================================================"
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo "======================================================================"
    echo ""
    echo "======================================================================"
    echo "Quick Start Guide"
    echo "======================================================================"
    echo ""
    echo "Manage dotfiles:"
    echo "  chezmoi edit ~/.bashrc        # Edit a dotfile"
    echo "  chezmoi diff                  # See changes"
    echo "  chezmoi apply                 # Apply changes"
    echo "  chezmoi update                # Pull from git and apply"
    echo ""
    echo "Setup fnox secrets (IMPORTANT!):"
    echo "  # Restore your age encryption key from backup:"
    echo "  cp /backup/fnox-key.txt ~/.config/fnox/key.txt"
    echo "  chmod 600 ~/.config/fnox/key.txt"
    echo ""
    echo "  # Or generate NEW key (only for first-time setup):"
    echo "  age-keygen -o ~/.config/fnox/key.txt"
    echo ""
    echo "  # Then use fnox:"
    echo "  fnox set DB_PASSWORD \"secret\"  # Set a secret"
    echo "  fnox get DB_PASSWORD             # Get a secret"
    echo "  fnox list                        # List all secrets"
    echo ""
    echo "To activate the new configuration, reload your shell:"
    echo "  source ~/.bashrc    # For bash"
    echo "  source ~/.zshrc     # For zsh"
    echo "  exec -l \$SHELL        # Or start a new shell"
    echo ""
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
    
    # Check requirements
    check_requirements
    
    # Install mise
    install_mise
    
    # Install chezmoi using mise
    install_chezmoi
    
    # Setup dotfiles (chezmoi will handle git clone)
    setup_dotfiles
    
    # Install all tools from mise config
    install_tools
    
    # Print summary
    print_summary
}

# Run main function
main "$@"
