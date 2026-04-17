#!/usr/bin/env bash
# Dotfiles Bootstrap Script (No-Sudo)
# Repository: https://github.com/msavdert/dotfiles
#
# Usage: curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash

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
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; }
log_step() { echo -e "${BLUE}==>${NC} $*"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

# =============================================================================
# Helper: GH CLI Installer (Minimal for Bootstrap)
# =============================================================================

install_gh_pre() {
    if command_exists gh; then return 0; fi
    log_step "Installing GitHub CLI (bootstrap priority)"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/cli/cli/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="2.61.0"

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="macOS_arm64" || os_type="macOS_amd64"
        filename="gh_${version}_${os_type}.zip"
        url="https://github.com/cli/cli/releases/download/v${version}/${filename}"
        curl -fsSL -L "$url" -o "/tmp/$filename"
        unzip -q -o "/tmp/$filename" -d "/tmp/gh_install"
        find "/tmp/gh_install" -name "gh" -exec cp {} "$BIN_DIR/" \;
    else
        [ "$arch" = "x86_64" ] && arch="amd64" || arch="arm64"
        filename="gh_${version}_linux_${arch}.tar.gz"
        url="https://github.com/cli/cli/releases/download/v${version}/${filename}"
        curl -fsSL -L "$url" -o "/tmp/$filename"
        tar -xzf "/tmp/$filename" -C "/tmp"
        cp "/tmp/gh_${version}_linux_${arch}/bin/gh" "$BIN_DIR/"
    fi
    chmod +x "$BIN_DIR/gh"
    rm -rf "/tmp/$filename" "/tmp/gh_install" "/tmp/gh_${version}_linux_"* 2>/dev/null || true
}

# =============================================================================
# Main Tasks
# =============================================================================

check_system_dependencies() {
    log_step "Checking system dependencies"
    # curl is omitted because we assume it exists if this script is running (curl | bash)
    # or it will fail naturally when first used.
    local required=(bash tar)
    local missing=()
    for tool in "${required[@]}"; do
        command_exists "$tool" && log "Found: $tool" || missing+=("$tool")
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing: ${missing[*]}"
        exit 1
    fi
}

fetch_dotfiles() {
    log_step "Fetching dotfiles repository"

    # Detect if we are running from within a dotfiles directory already
    # This is common in CI environments where the repo is already checked out
    if [ -f "scripts/install-tools.sh" ] && [ -f "scripts/link.sh" ] && [ ! -d "$DOTFILES_DIR" ]; then
        log "Detected local dotfiles repository. Linking to $DOTFILES_DIR..."
        ln -s "$(pwd)" "$DOTFILES_DIR"
        return 0
    fi

    if [ -d "$DOTFILES_DIR" ]; then
        if [ -d "$DOTFILES_DIR/.git" ]; then
            log "Dotfiles exists and is a git repo. Updating..."
            (cd "$DOTFILES_DIR" && git pull)
            return 0
        else
            log_warn "Dotfiles exists but is NOT a git repo. Re-fetching to ensure latest version..."
            rm -rf "$DOTFILES_DIR"
        fi
    fi

    # Try gh repo clone first (Best Practice with GH CLI)
    if command_exists git && command_exists gh; then
        log "Using gh repo clone..."
        if gh repo clone msavdert/dotfiles "$DOTFILES_DIR"; then
            return 0
        fi
    fi

    # Fallback 1: Standard git clone
    if command_exists git; then
        log "Cloning repository via git..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        # Fallback 2: Tarball
        log_warn "Git not found, falling back to tarball download."
        curl -fsSL "$DOTFILES_URL" -o "/tmp/dotfiles.tar.gz"
        mkdir -p "$DOTFILES_DIR"
        tar -xzf "/tmp/dotfiles.tar.gz" -C "$DOTFILES_DIR" --strip-components=1
        rm -f "/tmp/dotfiles.tar.gz"
    fi
}

main() {
    mkdir -p "$BIN_DIR"
    # Add BIN_DIR to PATH for current session
    export PATH="$BIN_DIR:$PATH"

    echo ""
    echo "======================================================================"
    echo "Dotfiles Bootstrap (No-Sudo)"
    echo "======================================================================"
    echo ""

    check_system_dependencies
    
    echo ""
    log_step "Step 1: Installing core tools..."
    install_gh_pre
    
    echo ""
    log_step "Step 2: Fetching dotfiles..."
    fetch_dotfiles

    echo ""
    log_step "Step 3: Installing tools and creating links..."
    # Run installation scripts from the repo
    bash "$DOTFILES_DIR/scripts/install-tools.sh"
    bash "$DOTFILES_DIR/scripts/link.sh"

    echo ""
    echo "======================================================================"
    echo -e "${GREEN}Bootstrap completed successfully!${NC}"
    echo "======================================================================"
    echo ""
    echo "Next steps:"
    echo "  source ~/.bashrc"
    
    if ! command_exists _get_comp_words_by_ref && [[ ! -f /usr/share/bash-completion/bash_completion ]]; then
        echo ""
        log_warn "Shell completion support is currently limited."
        echo "  To enable rich Tab-completions for gh, op, zellij, and uv, please install:"
        echo ""
        echo "  Ubuntu/Debian:  sudo apt update && sudo apt install -y bash-completion"
        echo "  RHEL/Fedora:    sudo dnf install -y bash-completion"
        echo "  macOS (Homebrew): brew install bash-completion@2"
        echo ""
    fi
    echo "======================================================================"
}

main "$@"
