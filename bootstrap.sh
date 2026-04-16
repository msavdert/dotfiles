#!/usr/bin/env bash
# Dotfiles Bootstrap Script
# Repository: https://github.com/msavdert/dotfiles
#
# Usage: curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
#
# This script:
# 1. Detects OS and installs required tools
# 2. Clones dotfiles to ~/.dotfiles
# 3. Creates symlinks to home directory
# 4. Prints setup instructions

set -euo pipefail

readonly DOTFILES_REPO="https://github.com/msavdert/dotfiles.git"
readonly DOTFILES_DIR="$HOME/.dotfiles"

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

is_linux() { [[ "$(uname -s)" == "Linux" ]]; }
is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_dnf_based() { command_exists dnf; }
is_apt_based() { command_exists apt-get; }

# =============================================================================
# System Detection
# =============================================================================

detect_os() {
    log_step "Detecting operating system"

    if is_macos; then
        log "Detected: macOS $(sw_vers -productVersion)"
        echo "darwin"
    elif is_dnf_based; then
        log "Detected: Linux (dnf-based)"
        echo "dnf"
    elif is_apt_based; then
        log "Detected: Linux (apt-based)"
        echo "apt"
    else
        log_error "Unsupported OS. Please install git, curl, and bash manually."
        exit 1
    fi
}

# =============================================================================
# Homebrew Installation (macOS only)
# =============================================================================

install_homebrew() {
    if ! command_exists brew; then
        log_step "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log "Homebrew already installed"
    fi
}

# =============================================================================
# Core Tool Installation
# =============================================================================

install_tools_darwin() {
    log_step "Installing tools via Homebrew"

    local -a brew_packages=(
        git
        curl
        bash
        tmux
        gh
        bash-completion@2
    )

    for pkg in "${brew_packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            log "Already installed: $pkg"
        else
            log "Installing: $pkg"
            brew install "$pkg"
        fi
    done

    log "Updating Homebrew"
    brew update
}

install_tools_apt() {
    log_step "Installing tools via apt"

    sudo apt-get update -qq

    local -a apt_packages=(
        git
        curl
        bash
        tmux
        gh
        bash-completion
        jq
    )

    for pkg in "${apt_packages[@]}"; do
        if dpkg -l "$pkg" &>/dev/null; then
            log "Already installed: $pkg"
        else
            log "Installing: $pkg"
            sudo apt-get install -y -qq "$pkg"
        fi
    done
}

install_tools_dnf() {
    log_step "Installing tools via dnf"

    local -a dnf_packages=(
        git
        curl
        bash
        tmux
        jq
    )

    for pkg in "${dnf_packages[@]}"; do
        if rpm -q "$pkg" &>/dev/null; then
            log "Already installed: $pkg"
        else
            log "Installing: $pkg"
            sudo dnf install -y -q "$pkg"
        fi
    done

    # Install gh (GitHub CLI) if not present
    if ! command_exists gh; then
        log "Installing GitHub CLI"
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq gh
    fi
}

# =============================================================================
# 1Password CLI Installation
# =============================================================================

install_1password_cli() {
    if command_exists op; then
        log "1Password CLI already installed: $(op --version)"
        return 0
    fi

    log_step "Installing 1Password CLI"

    if is_macos; then
        if command_exists brew; then
            brew install 1password-cli
        else
            log_warn "Homebrew not installed. Install 1Password CLI manually: https://1password.com/downloads/command-line/"
        fi
    elif is_dnf_based || is_apt_based; then
        local os_version
        os_version=$(grep -oP '(?<=VERSION_ID=)\d+' /etc/os-release 2>/dev/null || echo "0")

        # Debian/Ubuntu
        curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/${os_version} stable main" | sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq 1password-cli
    else
        log_warn "Could not install 1Password CLI automatically. See: https://1password.com/downloads/command-line/"
    fi
}

# =============================================================================
# Clone Dotfiles
# =============================================================================

clone_dotfiles() {
    log_step "Setting up dotfiles"

    if [ -d "$DOTFILES_DIR" ]; then
        log "Dotfiles already exist at $DOTFILES_DIR"
        log "Updating existing dotfiles..."
        cd "$DOTFILES_DIR"
        git pull origin main
    else
        log "Cloning dotfiles from $DOTFILES_REPO"
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
}

# =============================================================================
# Create Symlinks
# =============================================================================

create_symlinks() {
    log_step "Creating symlinks"

    local script_dir="$DOTFILES_DIR/scripts"
    if [ -x "$script_dir/link.sh" ]; then
        bash "$script_dir/link.sh"
    else
        log_warn "link.sh not found or not executable"
    fi
}

# =============================================================================
# Print Summary
# =============================================================================

print_summary() {
    echo ""
    echo "======================================================================"
    echo -e "${GREEN}Bootstrap completed successfully!${NC}"
    echo "======================================================================"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Set your git identity:"
    echo "   export GIT_AUTHOR_NAME=\"Your Name\""
    echo "   export GIT_AUTHOR_EMAIL=\"you@example.com\""
    echo ""
    echo "2. Sign in to 1Password:"
    echo "   op signin"
    echo ""
    echo "3. Authenticate GitHub CLI:"
    echo "   gh auth login"
    echo ""
    echo "4. Reload shell:"
    echo "   source ~/.bashrc"
    echo ""
    echo "======================================================================"
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "======================================================================"
    echo "Dotfiles Bootstrap"
    echo "======================================================================"
    echo ""

    # Detect OS
    local os
    os=$(detect_os)

    # Install tools based on OS
    if is_macos; then
        install_homebrew
        install_tools_darwin
    elif [ "$os" == "apt" ]; then
        install_tools_apt
    elif [ "$os" == "dnf" ]; then
        install_tools_dnf
    fi

    # Install 1Password CLI
    install_1password_cli

    # Clone dotfiles
    clone_dotfiles

    # Create symlinks
    create_symlinks

    # Print summary
    print_summary
}

main "$@"
