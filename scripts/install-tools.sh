#!/usr/bin/env bash
# Tool installation script
# Can be run independently to reinstall tools without re-cloning dotfiles

set -euo pipefail

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
# Homebrew (macOS)
# =============================================================================

install_homebrew() {
    if ! command_exists brew; then
        log_step "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log "Homebrew already installed"
    fi
}

install_darwin() {
    install_homebrew

    log_step "Installing tools via Homebrew"

    local -a packages=(
        git
        curl
        bash
        tmux
        gh
        bash-completion@2
    )

    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            log "Already installed: $pkg"
        else
            log "Installing: $pkg"
            brew install "$pkg"
        fi
    done

    brew update
    log "Done!"
}

# =============================================================================
# APT (Debian/Ubuntu)
# =============================================================================

install_apt() {
    log_step "Installing tools via apt"

    sudo apt-get update -qq

    local -a packages=(
        git
        curl
        bash
        tmux
        gh
        bash-completion
        jq
    )

    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" &>/dev/null; then
            log "Already installed: $pkg"
        else
            log "Installing: $pkg"
            sudo apt-get install -y -qq "$pkg"
        fi
    done

    log "Done!"
}

# =============================================================================
# DNF (RHEL/Rocky/Oracle Linux)
# =============================================================================

install_dnf() {
    log_step "Installing tools via dnf"

    local -a packages=(
        git
        curl
        bash
        tmux
        jq
    )

    for pkg in "${packages[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            log "Already installed: $pkg"
        else
            log "Installing: $pkg"
            sudo dnf install -y -q "$pkg"
        fi
    done

    # Install gh (GitHub CLI)
    if ! command_exists gh; then
        log "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq gh
    fi

    log "Done!"
}

# =============================================================================
# 1Password CLI
# =============================================================================

install_1password() {
    if command_exists op; then
        log "1Password CLI already installed: $(op --version)"
        return 0
    fi

    log_step "Installing 1Password CLI"

    if is_macos; then
        if command_exists brew; then
            brew install 1password-cli
        else
            log_warn "Homebrew not found. Install manually: https://1password.com/downloads/command-line/"
        fi
    elif command_exists apt-get; then
        local os_version
        os_version=$(grep -oP '(?<=VERSION_ID=)\d+' /etc/os-release 2>/dev/null || echo "8")

        curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/${os_version} stable main" | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq 1password-cli
    elif command_exists dnf; then
        sudo dnf config-manager --add-repo https://downloads.1password.com/linux/rpm/1password.repo
        sudo dnf install -y 1password-cli
    else
        log_warn "Could not install 1Password CLI automatically."
        log_warn "See: https://1password.com/downloads/command-line/"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "======================================================================"
    echo "Tool Installation"
    echo "======================================================================"
    echo ""

    if is_macos; then
        install_darwin
    elif command_exists apt-get; then
        install_apt
    elif command_exists dnf; then
        install_dnf
    else
        log_error "No supported package manager found."
        exit 1
    fi

    install_1password

    echo ""
    echo "======================================================================"
    echo "Installation complete!"
    echo "======================================================================"
}

main "$@"
