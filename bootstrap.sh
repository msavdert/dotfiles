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
log_step() { echo -e "${BLUE}==>${NC} $*"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

# =============================================================================
# Helper: GH CLI Installer (Pre-repo)
# =============================================================================

install_gh_pre() {
    if command_exists gh; then
        log "GitHub CLI already installed: $(gh --version | head -1)"
        return 0
    fi

    log_step "Installing GitHub CLI (bootstrap priority)"

    local version arch os_type filename url
    # Fetch latest version without jq, safely avoiding SIGPIPE
    version=$(curl -fsSL -I https://github.com/cli/cli/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="2.61.0"

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="macOS_arm64" || os_type="macOS_amd64"
        filename="gh_${version}_${os_type}.zip"
        url="https://github.com/cli/cli/releases/download/v${version}/${filename}"
        log "Downloading gh $version for macOS..."
        curl -fsSL -L "$url" -o "/tmp/$filename"
        # macOS always has unzip
        unzip -q -o "/tmp/$filename" -d "/tmp/gh_install"
        find "/tmp/gh_install" -name "gh" -exec cp {} "$BIN_DIR/" \;
        rm -rf "/tmp/$filename" "/tmp/gh_install"
    else
        case "$arch" in
            x86_64) arch="amd64" ;;
            aarch64|arm64) arch="arm64" ;;
            *) arch="386" ;;
        esac
        filename="gh_${version}_linux_${arch}.tar.gz"
        url="https://github.com/cli/cli/releases/download/v${version}/${filename}"
        log "Downloading gh $version for Linux ($arch)..."
        curl -fsSL -L "$url" -o "/tmp/$filename"
        tar -xzf "/tmp/$filename" -C "/tmp"
        cp "/tmp/gh_${version}_linux_${arch}/bin/gh" "$BIN_DIR/"
        rm -rf "/tmp/$filename" "/tmp/gh_${version}_linux_${arch}"
    fi
    chmod +x "$BIN_DIR/gh"
}

# =============================================================================
# Main Tasks
# =============================================================================

check_system_dependencies() {
    log_step "Checking system dependencies"
    local required=(bash curl tar)
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

    if command_exists git; then
        log "Cloning repository via git..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
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

    check_system_dependencies
    install_gh_pre
    fetch_dotfiles

    # Run installation scripts from the repo
    bash "$DOTFILES_DIR/scripts/install-tools.sh"
    bash "$DOTFILES_DIR/scripts/link.sh"

    log_step "Bootstrap completed successfully!"
    echo "Next steps: source ~/.bashrc"
}

main "$@"
