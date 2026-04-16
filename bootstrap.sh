#!/usr/bin/env bash
# Dotfiles Bootstrap Script
# Repository: https://github.com/msavdert/dotfiles
#
# Usage: curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
#
# This script:
# 1. Checks for required system tools (bash, curl, unzip, tar)
# 2. Fetches the dotfiles repository (git clone or zip download)
# 3. Invokes scripts/install-tools.sh (binary downloads to ~/.local/bin)
# 4. Invokes scripts/link.sh (creates symlinks)

set -euo pipefail

readonly DOTFILES_URL="https://github.com/msavdert/dotfiles/archive/refs/heads/main.tar.gz"
readonly DOTFILES_REPO="https://github.com/msavdert/dotfiles.git"
readonly DOTFILES_DIR="$HOME/.dotfiles"
readonly BIN_DIR="$HOME/.local/bin"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "${BLUE}==>${NC} $*"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

# =============================================================================
# Required Tools Check
# =============================================================================

check_system_dependencies() {
    log_step "Checking system dependencies"

    local missing=()
    local required=(bash curl tar)

    for tool in "${required[@]}"; do
        if command_exists "$tool"; then
            log "Found: $tool"
        else
            log_error "Missing: $tool"
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        echo "======================================================================"
        echo -e "${RED}ERROR: Missing system dependencies${NC}"
        echo "======================================================================"
        echo "Please ask your system administrator to install the following:"
        echo ""
        echo "  On Ubuntu/Debian: sudo apt install ${missing[*]}"
        echo "  On RHEL/Rocky:    sudo dnf install ${missing[*]}"
        echo "  On macOS:         xcode-select --install"
        echo ""
        echo "Then re-run this script."
        echo "======================================================================"
        exit 1
    fi
}

# =============================================================================
# macOS Homebrew Check
# =============================================================================

check_macos_brew() {
    if is_macos && ! command_exists brew; then
        log_warn "Homebrew is missing."
        echo ""
        echo "Homebrew is recommended for macOS. You can install it with:"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo ""
        log_error "Please install Homebrew and try again."
        exit 1
    fi
}

# =============================================================================
# Fetch Dotfiles
# =============================================================================

fetch_dotfiles() {
    log_step "Fetching dotfiles repository"

    if [ -d "$DOTFILES_DIR" ]; then
        log "Dotfiles already exist at $DOTFILES_DIR"
        return 0
    fi

    if command_exists git; then
        log "Cloning repository via git..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        log_warn "Git not found, falling back to tarball download."
        curl -fsSL "$DOTFILES_URL" -o "/tmp/dotfiles.tar.gz"
        mkdir -p "$DOTFILES_DIR"
        tar -xzf "/tmp/dotfiles.tar.gz" -C "$DOTFILES_DIR" --strip-components=1
        rm -f "/tmp/dotfiles.tar.gz"
        log "Repository downloaded as tarball. Note: git features will be unavailable."
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "======================================================================"
    echo "Dotfiles Bootstrap (No-Sudo)"
    echo "======================================================================"
    echo ""

    check_system_dependencies
    check_macos_brew
    fetch_dotfiles

    # Ensure ~/.local/bin exists
    mkdir -p "$BIN_DIR"

    # Run installation scripts from the repo
    if [ -f "$DOTFILES_DIR/scripts/install-tools.sh" ]; then
        bash "$DOTFILES_DIR/scripts/install-tools.sh"
    else
        log_error "scripts/install-tools.sh not found!"
        exit 1
    fi

    if [ -f "$DOTFILES_DIR/scripts/link.sh" ]; then
        bash "$DOTFILES_DIR/scripts/link.sh"
    else
        log_error "scripts/link.sh not found!"
        exit 1
    fi

    echo ""
    echo "======================================================================"
    echo -e "${GREEN}Bootstrap completed successfully!${NC}"
    echo "======================================================================"
    echo ""
    echo "Next steps:"
    echo "1. Sign in to 1Password:  op signin"
    echo "2. Reload shell:          source ~/.bashrc"
    echo "======================================================================"
}

main "$@"
