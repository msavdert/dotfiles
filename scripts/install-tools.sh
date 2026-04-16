#!/usr/bin/env bash
# Tool installation script (No-Sudo)
# Installs gh, op, zellij, and jq as binaries to ~/.local/bin

set -euo pipefail

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

ensure_bin_dir() {
    if [ ! -d "$BIN_DIR" ]; then
        mkdir -p "$BIN_DIR"
        log "Created $BIN_DIR"
    fi
}

# Helper to extract ZIP files without requiring the unzip utility
extract_zip() {
    local zip_file="$1"
    local dest_dir="$2"
    local entry="${3:-}" # Optional: specific file to extract

    if command_exists unzip; then
        if [ -n "$entry" ]; then
            unzip -q -o "$zip_file" -d "$dest_dir" "$entry"
        else
            unzip -q -o "$zip_file" -d "$dest_dir"
        fi
    elif command_exists python3; then
        log "unzip missing, using python3 to extract..."
        if [ -n "$entry" ]; then
            python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extract(sys.argv[3], sys.argv[2])" "$zip_file" "$dest_dir" "$entry"
        else
            python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip_file" "$dest_dir"
        fi
    elif command_exists python; then
        log "unzip missing, using python to extract..."
        if [ -n "$entry" ]; then
            python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extract(sys.argv[3], sys.argv[2])" "$zip_file" "$dest_dir" "$entry"
        else
            python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip_file" "$dest_dir"
        fi
    else
        log_error "unzip and python (zipfile) missing. Cannot extract $zip_file"
        return 1
    fi
}

# =============================================================================
# Binary Installers
# =============================================================================

install_zellij() {
    if command_exists zellij; then
        log "Zellij already installed: $(zellij --version 2>&1 | head -1)"
        return 0
    fi

    log_step "Installing Zellij"

    local version arch filename url
    version=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\?\([^"]*\)".*/\1/' | head -1)
    [ -z "$version" ] && version="0.41.2"

    arch=$(uname -m)
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *) log_warn "Unsupported arch: $arch, skipping zellij"; return 0 ;;
    esac

    if is_macos; then
        filename="zellij-$arch-apple-darwin.tar.gz"
    else
        filename="zellij-$arch-unknown-linux-musl.tar.gz"
    fi

    url="https://github.com/zellij-org/zellij/releases/download/v${version}/${filename}"
    log "Downloading zellij $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    tar -xzf "/tmp/$filename" -C "$BIN_DIR"
    chmod +x "$BIN_DIR/zellij"
    rm -f "/tmp/$filename"
}

install_gh() {
    if command_exists gh; then
        log "GitHub CLI already installed: $(gh --version | head -1)"
        return 0
    fi

    log_step "Installing GitHub CLI"

    local version arch os_type filename url
    version=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest 2>/dev/null | grep '"tag_name"' | sed 's/.*"v\?\([^"]*\)".*/\1/' | head -1)
    [ -z "$version" ] && version="2.61.0"

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="macOS_arm64" || os_type="macOS_amd64"
        filename="gh_${version}_${os_type}.zip"
        url="https://github.com/cli/cli/releases/download/v${version}/${filename}"
        curl -fsSL -L "$url" -o "/tmp/$filename"
        mkdir -p "/tmp/gh_install"
        extract_zip "/tmp/$filename" "/tmp/gh_install"
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
        curl -fsSL -L "$url" -o "/tmp/$filename"
        tar -xzf "/tmp/$filename" -C "/tmp"
        cp "/tmp/gh_${version}_linux_${arch}/bin/gh" "$BIN_DIR/"
        rm -rf "/tmp/$filename" "/tmp/gh_${version}_linux_${arch}"
    fi
    chmod +x "$BIN_DIR/gh"
}

install_op() {
    if command_exists op; then
        log "1Password CLI already installed: $(op --version)"
        return 0
    fi

    log_step "Installing 1Password CLI"

    local version arch filename url
    # Fetch latest stable version from update page
    # Using python3 if available for robust parsing, or a fallback string
    if command_exists python3; then
        version=$(python3 -c "import urllib.request, re; content = urllib.request.urlopen('https://app-updates.agilebits.com/product_history/CLI2').read().decode(); links = re.findall(r'v([0-9.]+)/op_linux', content); print(links[0] if links else '2.33.1')" 2>/dev/null || echo "2.33.1")
    else
        version="2.33.1"
    fi

    arch=$(uname -m)
    [ "$arch" = "x86_64" ] && arch="amd64" || arch="arm64"

    if is_macos; then
        filename="op_darwin_${arch}_v${version}.zip"
        url="https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/$filename"
    else
        filename="op_linux_${arch}_v${version}.zip"
        url="https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/$filename"
    fi

    log "Downloading op $version..."
    curl -fsSL "$url" -o "/tmp/$filename"
    extract_zip "/tmp/$filename" "$BIN_DIR" "op"
    chmod +x "$BIN_DIR/op"
    rm -f "/tmp/$filename"
}

install_jq() {
    if command_exists jq; then
        log "jq already installed: $(jq --version)"
        return 0
    fi

    log_step "Installing jq"

    local version="1.7.1"
    local arch url
    arch=$(uname -m)
    
    if is_macos; then
        # jqlang provides specific binaries for macos
        [ "$arch" = "arm64" ] && url="https://github.com/jqlang/jq/releases/download/jq-${version}/jq-macos-arm64" || url="https://github.com/jqlang/jq/releases/download/jq-${version}/jq-macos-amd64"
    else
        [ "$arch" = "x86_64" ] && arch="amd64" || arch="arm64"
        url="https://github.com/jqlang/jq/releases/download/jq-${version}/jq-linux-${arch}"
    fi

    log "Downloading jq $version..."
    curl -fsSL -L "$url" -o "$BIN_DIR/jq"
    chmod +x "$BIN_DIR/jq"
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "======================================================================"
    echo "Tool Installation (No-Sudo)"
    echo "======================================================================"
    echo ""

    ensure_bin_dir
    
    # Export PATH just in case
    export PATH="$BIN_DIR:$PATH"

    if is_macos && command_exists brew; then
        log_step "Homebrew detected, using it for tools"
        brew install gh 1password-cli zellij jq 2>/dev/null || true
    else
        install_gh
        install_op
        install_zellij
        install_jq
    fi

    echo ""
    echo "======================================================================"
    echo "Installation complete!"
    echo "Next steps: source ~/.bashrc"
    echo "======================================================================"
}

main "$@"
