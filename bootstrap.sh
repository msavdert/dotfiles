#!/usr/bin/env bash
# Dotfiles Bootstrap Script
# Repository: https://github.com/msavdert/dotfiles
#
# Usage: curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
#
# This script:
# 1. Checks for required tools (curl, bash)
# 2. Installs zellij, gh, op, jq via direct binary downloads
# 3. Downloads dotfiles repo as a zip from GitHub
# 4. Creates symlinks to home directory
# 5. Prints setup instructions
#
# NOTE: This script does NOT use sudo. Required system packages must be
# installed manually via root before running this script.

set -euo pipefail

readonly DOTFILES_URL="https://github.com/msavdert/dotfiles/archive/refs/heads/main.zip"
readonly DOTFILES_DIR="$HOME/.dotfiles"
readonly INSTALL_DIR="$HOME/bin"

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

# =============================================================================
# System Detection
# =============================================================================

detect_os() {
    log_step "Detecting operating system"

    if is_macos; then
        log "Detected: macOS $(sw_vers -productVersion)"
    elif [ -f /etc/os-release ]; then
        if grep -q "ID=fedora" /etc/os-release || grep -q "ID=rhel" /etc/os-release || grep -q "ID=rocky" /etc/os-release || grep -q "ID=almalinux" /etc/os-release; then
            log "Detected: Linux (dnf-based)"
        elif grep -q "ID=debian" /etc/os-release || grep -q "ID=ubuntu" /etc/os-release; then
            log "Detected: Linux (apt-based)"
        else
            log "Detected: Linux (unknown distro)"
        fi
    else
        log "Detected: Linux (unknown)"
    fi
}

# =============================================================================
# Required Tools Check
# =============================================================================

readonly REQUIRED_TOOLS=(curl bash)  # used by check_required_tools
check_required_tools() {
    log_step "Checking required tools"

    local missing=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if command_exists "$tool"; then
            local version
            version=$("$tool" --version 2>&1 | head -1 || echo "unknown")
            log "Found: $tool ($version)"
        else
            log_error "Missing: $tool"
            missing+=("$tool")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        echo "======================================================================"
        echo -e "${RED}ERROR: Missing required tools${NC}"
        echo "======================================================================"
        echo ""
        echo "The following tools must be installed via root (sudo) before"
        echo "running this bootstrap script:"
        echo ""
        for tool in "${missing[@]}"; do
            echo "  - $tool"
        done
        echo ""
        echo "On macOS, install Xcode Command Line Tools:"
        echo "  xcode-select --install"
        echo ""
        echo "On Linux (apt):"
        echo "  sudo apt-get install ${missing[*]}"
        echo ""
        echo "On Linux (dnf):"
        echo "  sudo dnf install ${missing[*]}"
        echo ""
        echo "After installing the above, re-run this script."
        echo "======================================================================"
        exit 1
    fi
}

# =============================================================================
# Install Directory Setup
# =============================================================================

ensure_install_dir() {
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        log "Created $INSTALL_DIR"
    fi
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        export PATH="$INSTALL_DIR:$PATH"
        log "Added $INSTALL_DIR to PATH"
    fi
}

# =============================================================================
# Optional Tools - Direct Binary Downloads
# =============================================================================

install_zellij() {
    if command_exists zellij; then
        log "Zellij already installed: $(zellij --version 2>&1 | head -1)"
        return 0
    fi

    log_step "Installing Zellij"

    local version url filename

    version=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\?\([^"]*\)".*/\1/' | head -1)
    if [ -z "$version" ]; then
        log_warn "Could not fetch latest zellij release, trying known version"
        version="0.41.2"
    fi

    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *)
            log_warn "Unsupported arch: $arch, skipping zellij"
            return 0
            ;;
    esac

    if is_macos; then
        filename="zellij-$arch-apple-darwin.tar.gz"
    else
        filename="zellij-$arch-unknown-linux-musl.tar.gz"
    fi

    url="https://github.com/zellij-org/zellij/releases/download/${version}/${filename}"
    log "Downloading $url"
    curl -fsSL "$url" -o "/tmp/$filename" || {
        log_warn "Failed to download zellij, skipping installation"
        return 0
    }
    tar -xzf "/tmp/$filename" -C "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/zellij"
    rm -f "/tmp/$filename"
    log "Zellij installed: $("$INSTALL_DIR/zellij" --version 2>&1 | head -1)"
}

install_gh() {
    if command_exists gh; then
        log "GitHub CLI already installed: $(gh --version | head -1)"
        return 0
    fi

    log_step "Installing GitHub CLI"

    local version
    version=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\?\([^"]*\)".*/\1/' | head -1)

    if [ -z "$version" ]; then
        log_warn "Could not fetch latest gh release, trying known version"
        version="2.61.0"
    fi

    local arch os_type filename url
    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="macOS_arm64" || os_type="macOS_amd64"
        filename="gh_${version}_${os_type}.zip"
        url="https://github.com/cli/cli/releases/download/v${version}/${filename}"
        log "Downloading $url"
        curl -fsSL "$url" -o "/tmp/$filename"
        unzip -o "/tmp/$filename" -d "$INSTALL_DIR" 2>/dev/null || {
            unzip -o "/tmp/$filename" -d /tmp/gh_unzip
            mv /tmp/gh_unzip/gh*/bin/gh "$INSTALL_DIR/" 2>/dev/null || mv /tmp/gh_unzip/gh "$INSTALL_DIR/" 2>/dev/null || true
        }
        rm -f "/tmp/$filename"
    else
        case "$arch" in
            x86_64) arch="amd64" ;;
            aarch64|arm64) arch="arm64" ;;
            *) arch="386" ;;
        esac
        filename="gh_${version}_linux_${arch}.tar.gz"
        url="https://github.com/cli/cli/releases/download/v${version}/${filename}"
        log "Downloading $url"
        curl -fsSL "$url" -o "/tmp/$filename"
        tar -xzf "/tmp/$filename" -C /tmp
        cp /tmp/gh_"$version"/bin/gh "$INSTALL_DIR/"
        rm -rf "/tmp/$filename" "/tmp/gh_$version"
    fi

    chmod +x "$INSTALL_DIR/gh"
    log "GitHub CLI installed: $("$INSTALL_DIR/gh" --version | head -1)"
}

install_op() {
    if command_exists op; then
        log "1Password CLI already installed: $(op --version)"
        return 0
    fi

    log_step "Installing 1Password CLI"

    local version
    version=$(curl -fsSL https://api.github.com/repos/1Password/op/releases/latest 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\?\([^"]*\)".*/\1/' | head -1)
    [ -z "$version" ] && version="2.28.0"

    local filename url
    if is_macos; then
        filename="op_${version}_darwin_amd64.zip"
        url="https://cache.agilebits.com/dist/1P/op/v${version}/$filename"
    else
        filename="op_${version}_linux_amd64.zip"
        url="https://cache.agilebits.com/dist/1P/op/v${version}/$filename"
    fi

    log "Downloading $url"
    curl -fsSL "$url" -o "/tmp/$filename"
    unzip -o "/tmp/$filename" -d "$INSTALL_DIR"
    rm -f "/tmp/$filename"
    chmod +x "$INSTALL_DIR/op"
    log "1Password CLI installed: $("$INSTALL_DIR/op" --version)"
}

install_jq() {
    if command_exists jq; then
        log "jq already installed: $(jq --version)"
        return 0
    fi

    log_step "Installing jq"

    local version="1.7.1"
    local arch uname_arch url filename
    uname_arch=$(uname -m)
    case "$uname_arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            log_warn "Unsupported arch: $uname_arch for jq, skipping"
            return 0
            ;;
    esac

    if is_macos; then
        filename="jq-osx-$arch"
        url="https://github.com/jqlang/jq/releases/download/jq-${version}/${filename}"
    else
        filename="jq-linux-$arch"
        url="https://github.com/jqlang/jq/releases/download/jq-${version}/${filename}"
    fi

    log "Downloading $url"
    curl -fsSL "$url" -o "$INSTALL_DIR/jq"
    chmod +x "$INSTALL_DIR/jq"
    log "jq installed: $("$INSTALL_DIR/jq" --version)"
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
# Optional Tools via Homebrew (macOS)
# =============================================================================

install_tools_darwin_homebrew() {
    log_step "Installing tools via Homebrew"

    local -a brew_packages=(
        curl
        bash
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

# =============================================================================
# Download Dotfiles
# =============================================================================

fetch_dotfiles() {
    log_step "Setting up dotfiles"

    if [ -d "$DOTFILES_DIR" ]; then
        log "Dotfiles already exist at $DOTFILES_DIR"
        log "Dotfiles update must be done manually: cd $DOTFILES_DIR && git pull"
    else
        log "Downloading dotfiles from GitHub"
        curl -fsSL "$DOTFILES_URL" -o "/tmp/dotfiles.zip"
        unzip -o "/tmp/dotfiles.zip" -d /tmp
        mv /tmp/dotfiles-main "$DOTFILES_DIR"
        rm -f "/tmp/dotfiles.zip"
        log "Dotfiles installed at $DOTFILES_DIR"
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

    detect_os
    check_required_tools
    ensure_install_dir

    # Install terminal multiplexer and CLI tools via direct binary downloads
    install_zellij
    install_gh
    install_op
    install_jq

    # On macOS, use Homebrew for base tools if available
    if is_macos; then
        if command_exists brew; then
            install_tools_darwin_homebrew
        else
            install_homebrew
            install_tools_darwin_homebrew
        fi
    fi

    fetch_dotfiles
    create_symlinks
    print_summary
}

main "$@"
