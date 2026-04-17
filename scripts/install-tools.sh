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
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; }
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
    elif command_exists uv; then
        log "unzip and python missing, attempting to use uv for extraction..."
        # Ensure a python is available via uv
        if ! uv python find 3.12 &>/dev/null; then
            log "uv: installing a standalone python 3.12 into ~/.local/share/uv..."
            uv python install 3.12
        fi
        
        if [ -n "$entry" ]; then
            uv run --python 3.12 python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extract(sys.argv[3], sys.argv[2])" "$zip_file" "$dest_dir" "$entry"
        else
            uv run --python 3.12 python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip_file" "$dest_dir"
        fi
    else
        log_error "unzip, python, and uv missing. Cannot extract $zip_file"
        return 1
    fi
}

# =============================================================================
# Binary Installers
# =============================================================================

install_zellij() {
    if command_exists zellij; then
        log_skip "Zellij already installed: $(zellij --version 2>&1 | head -1)"
        return 0
    fi

    log_step "Installing Zellij"

    local version arch filename url
    # Use Redirect method to avoid GitHub API rate limits
    version=$(curl -fsSL -I https://github.com/zellij-org/zellij/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="0.44.1"

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
        log_skip "GitHub CLI already installed: $(gh --version | head -1)"
        return 0
    fi

    log_step "Installing GitHub CLI"

    local version arch os_type filename url
    # Use Redirect method to avoid GitHub API rate limits
    version=$(curl -fsSL -I https://github.com/cli/cli/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
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
        log_skip "1Password CLI already installed: $(op --version)"
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
        log_skip "jq already installed: $(jq --version | head -1)"
        return 0
    fi

    log_step "Installing jq"

    local version arch url
    # Use Redirect method to avoid GitHub API rate limits
    version=$(curl -fsSL -I https://github.com/jqlang/jq/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/jq-//')
    [ -z "$version" ] && version="1.7.1"

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

install_nvim() {
    if command_exists nvim; then
        log_skip "Neovim already installed: $(nvim --version | head -1)"
        return 0
    fi

    log_step "Installing Neovim"

    # Check for GLIBC version (min 2.32 required for latest nvim binaries)
    if ! is_macos; then
        local glibc_version=$(ldd --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
        # Bash floating point comparison trick
        if [ "$(echo "$glibc_version < 2.32" | bc -l 2>/dev/null || awk "BEGIN {print ($glibc_version < 2.32)}")" -eq 1 ]; then
            log_warn "System GLIBC ($glibc_version) is too old for latest Neovim (min 2.32). Skipping Neovim installation."
            return 0
        fi
    fi

    local version arch os_type filename url
    # Use Redirect method to avoid GitHub API rate limits
    version=$(curl -fsSL -I https://github.com/neovim/neovim/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="0.10.0"

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="macos-arm64" || os_type="macos-x86_64"
        filename="nvim-${os_type}.tar.gz"
    else
        case "$arch" in
            x86_64) os_type="linux-x86_64" ;;
            aarch64|arm64) os_type="linux-arm64" ;;
            *) log_warn "Neovim pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
        # Neovim v0.10.0 might use nvim-linux64 for x86_64, but v0.12+ uses nvim-linux-x86_64
        # We try to use the most common pattern or the exact one we found
        filename="nvim-${os_type}.tar.gz"
    fi

    url="https://github.com/neovim/neovim/releases/download/v${version}/${filename}"
    log "Downloading Neovim $version for $os_type..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    mkdir -p "$HOME/.local/apps"
    rm -rf "$HOME/.local/apps/nvim"
    
    # Extract
    tar -xzf "/tmp/$filename" -C "$HOME/.local/apps"
    
    # The tarball extracts to nvim-<os_type> or nvim-linux64
    local extracted_dir=$(find "$HOME/.local/apps" -maxdepth 1 -name "nvim-*" -type d | head -1)
    if [ -n "$extracted_dir" ]; then
        mv "$extracted_dir" "$HOME/.local/apps/nvim"
    else
        log_error "Could not find extracted Neovim directory"
        return 1
    fi
    
    # Link the binary
    ln -sf "$HOME/.local/apps/nvim/bin/nvim" "$BIN_DIR/nvim"
    chmod +x "$BIN_DIR/nvim"
    rm -f "/tmp/$filename"
}

install_uv() {
    if command_exists uv; then
        log_skip "uv already installed: $(uv --version 2>&1 | head -1)"
        return 0
    fi

    log_step "Installing uv (Python manager)"

    local version arch os_type filename url
    # Use Redirect method to avoid GitHub API rate limits
    version=$(curl -fsSL -I https://github.com/astral-sh/uv/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="0.4.0"

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-gnu" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-gnu" ;;
            *) log_warn "uv pre-built binaries not found for $arch, skipping."; return 0 ;;
        esac
    fi

    filename="uv-${os_type}.tar.gz"
    url="https://github.com/astral-sh/uv/releases/download/${version}/${filename}"
    
    log "Downloading uv $version for $os_type..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    # Extract
    mkdir -p "/tmp/uv_install"
    tar -xzf "/tmp/$filename" -C "/tmp/uv_install"
    
    # uv tarball contains a directory uv-x86_64-unknown-linux-gnu/ which contains uv and uvx
    local extracted_dir=$(find "/tmp/uv_install" -maxdepth 1 -name "uv-*" -type d | head -1)
    if [ -n "$extracted_dir" ]; then
        cp "$extracted_dir/uv" "$BIN_DIR/uv"
        cp "$extracted_dir/uvx" "$BIN_DIR/uvx"
    else
        log_error "Could not find extracted uv directory"
        return 1
    fi
    
    chmod +x "$BIN_DIR/uv" "$BIN_DIR/uvx"
    rm -rf "/tmp/$filename" "/tmp/uv_install"
}

install_rg() {
    if command_exists rg; then
        log_skip "ripgrep already installed: $(rg --version | head -1)"
        return 0
    fi

    log_step "Installing ripgrep (rg)"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/BurntSushi/ripgrep/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="14.1.0"

    arch=$(uname -m)
    if is_macos; then
        if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
            filename="ripgrep-${version}-aarch64-apple-darwin.tar.gz"
        else
            filename="ripgrep-${version}-x86_64-apple-darwin.tar.gz"
        fi
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-gnu" ;; # ripgrep uses -gnu for aarch64
            *) log_warn "ripgrep pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
        filename="ripgrep-${version}-${os_type}.tar.gz"
    fi

    url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/${filename}"
    log "Downloading ripgrep $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "ripgrep-*" -type d | head -1)
    cp "$extracted_dir/rg" "$BIN_DIR/"
    chmod +x "$BIN_DIR/rg"
    rm -rf "/tmp/$filename" "$extracted_dir"
}

install_fd() {
    if command_exists fd; then
        log_skip "fd already installed: $(fd --version)"
        return 0
    fi

    log_step "Installing fd"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/sharkdp/fd/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="10.1.0"

    arch=$(uname -m)
    if is_macos; then
        if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
            filename="fd-v${version}-aarch64-apple-darwin.tar.gz"
        else
            filename="fd-v${version}-x86_64-apple-darwin.tar.gz"
        fi
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
            *) log_warn "fd pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
        filename="fd-v${version}-${os_type}.tar.gz"
    fi

    url="https://github.com/sharkdp/fd/releases/download/v${version}/${filename}"
    log "Downloading fd $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "fd-v*" -type d | head -1)
    cp "$extracted_dir/fd" "$BIN_DIR/"
    chmod +x "$BIN_DIR/fd"
    rm -rf "/tmp/$filename" "$extracted_dir"
}

install_bat() {
    if command_exists bat; then
        log_skip "bat already installed: $(bat --version)"
        return 0
    fi

    log_step "Installing bat"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/sharkdp/bat/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="0.24.0"

    arch=$(uname -m)
    if is_macos; then
        if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
            filename="bat-v${version}-aarch64-apple-darwin.tar.gz"
        else
            filename="bat-v${version}-x86_64-apple-darwin.tar.gz"
        fi
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
            *) log_warn "bat pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
        filename="bat-v${version}-${os_type}.tar.gz"
    fi

    url="https://github.com/sharkdp/bat/releases/download/v${version}/${filename}"
    log "Downloading bat $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "bat-v*" -type d | head -1)
    cp "$extracted_dir/bat" "$BIN_DIR/"
    chmod +x "$BIN_DIR/bat"
    rm -rf "/tmp/$filename" "$extracted_dir"
}

install_eza() {
    if command_exists eza; then
        log_skip "eza already installed: $(eza --version | head -1)"
        return 0
    fi

    log_step "Installing eza"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/eza-community/eza/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="0.18.15"

    arch=$(uname -m)
    if is_macos; then
        # eza usually doesn't provide macOS binaries in releases, Homebrew is preferred.
        # This fallback is unlikely to work for latest versions without a direct link.
        filename="eza_x86_64-apple-darwin.zip"
        url="https://github.com/eza-community/eza/releases/download/v${version}/${filename}"
        log "Attempting to download eza $version for macOS..."
        curl -fsSL -L "$url" -o "/tmp/$filename"
        extract_zip "/tmp/$filename" "$BIN_DIR" "eza"
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-gnu" ;; # eza uses -gnu for aarch64
            *) log_warn "eza pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
        filename="eza_${os_type}.tar.gz"
        url="https://github.com/eza-community/eza/releases/download/v${version}/${filename}"
        log "Downloading eza $version..."
        curl -fsSL -L "$url" -o "/tmp/$filename"
        tar -xzf "/tmp/$filename" -C "$BIN_DIR"
        
        # Install completions
        log "Downloading eza completions..."
        local comp_url="https://github.com/eza-community/eza/releases/download/v${version}/completions-${version}.tar.gz"
        local comp_filename="eza_completion.tar.gz"
        local comp_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
        local tmp_eza_extract="/tmp/eza_comp_extract"
        
        mkdir -p "$comp_dir"
        mkdir -p "$tmp_eza_extract"
        curl -fsSL -L "$comp_url" -o "/tmp/$comp_filename"
        tar -xzf "/tmp/$comp_filename" -C "$tmp_eza_extract"
        # completions tarball contains a target/ directory or files directly
        local eza_comp_file=$(find "$tmp_eza_extract" -name "eza.bash" | head -1)
        if [ -n "$eza_comp_file" ]; then
            cp "$eza_comp_file" "$comp_dir/eza"
            log "Installed eza completion"
        fi
        rm -rf "$tmp_eza_extract" "/tmp/$comp_filename" 2>/dev/null || true
    fi
    chmod +x "$BIN_DIR/eza"
    rm -f "/tmp/$filename"
}

install_fzf() {
    if command_exists fzf; then
        log_skip "fzf already installed: $(fzf --version)"
        return 0
    fi

    log_step "Installing fzf"

    local version arch os_type filename url tag
    tag=$(curl -fsSL -I https://github.com/junegunn/fzf/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r')
    [ -z "$tag" ] && tag="v0.71.0"
    version=$(echo "$tag" | sed 's/^v//')

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="darwin_arm64" || os_type="darwin_amd64"
    else
        [ "$arch" = "x86_64" ] && os_type="linux_amd64" || os_type="linux_arm64"
    fi

    filename="fzf-${version}-${os_type}.tar.gz"
    url="https://github.com/junegunn/fzf/releases/download/${tag}/${filename}"
    
    log "Downloading fzf $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "$BIN_DIR"
    chmod +x "$BIN_DIR/fzf"
    rm -f "/tmp/$filename"
}

install_zoxide() {
    if command_exists zoxide; then
        log_skip "zoxide already installed: $(zoxide --version | head -1)"
        return 0
    fi

    log_step "Installing zoxide"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/ajeetdsouza/zoxide/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="0.9.4"

    arch=$(uname -m)
    if is_macos; then
        if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
            filename="zoxide-${version}-aarch64-apple-darwin.tar.gz"
        else
            filename="zoxide-${version}-x86_64-apple-darwin.tar.gz"
        fi
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
            *) log_warn "zoxide pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
        filename="zoxide-${version}-${os_type}.tar.gz"
    fi

    url="https://github.com/ajeetdsouza/zoxide/releases/download/v${version}/${filename}"
    log "Downloading zoxide $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "$BIN_DIR"
    chmod +x "$BIN_DIR/zoxide"
    rm -f "/tmp/$filename"
}

install_delta() {
    if command_exists delta; then
        log_skip "delta already installed: $(delta --version | head -1)"
        return 0
    fi

    log_step "Installing delta"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/dandavison/delta/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="0.17.0"

    arch=$(uname -m)
    if is_macos; then
        if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
            filename="delta-${version}-aarch64-apple-darwin.tar.gz"
        else
            filename="delta-${version}-x86_64-apple-darwin.tar.gz"
        fi
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-gnu" ;; # delta uses -gnu for aarch64
            *) log_warn "delta pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
        filename="delta-${version}-${os_type}.tar.gz"
    fi

    url="https://github.com/dandavison/delta/releases/download/${version}/${filename}"
    log "Downloading delta $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "delta-${version}-*" -type d | head -1)
    cp "$extracted_dir/delta" "$BIN_DIR/"
    chmod +x "$BIN_DIR/delta"
    rm -rf "/tmp/$filename" "$extracted_dir"
}

install_starship() {
    if command_exists starship; then
        log_skip "starship already installed: $(starship --version | head -1)"
        return 0
    fi

    log_step "Installing starship"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/starship/starship/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="1.19.0"

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
            *) log_warn "starship pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
    fi

    filename="starship-${os_type}.tar.gz"
    url="https://github.com/starship/starship/releases/download/v${version}/${filename}"
    
    log "Downloading starship $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "$BIN_DIR"
    chmod +x "$BIN_DIR/starship"
    rm -f "/tmp/$filename"
}

install_bottom() {
    if command_exists btm; then
        log_skip "bottom (btm) already installed: $(btm --version)"
        return 0
    fi

    log_step "Installing bottom (btm)"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/ClementTsang/bottom/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r')
    [ -z "$version" ] && version="0.10.2"

    arch=$(uname -m)
    if is_macos; then
        if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
            filename="bottom_aarch64-apple-darwin.tar.gz"
        else
            filename="bottom_x86_64-apple-darwin.tar.gz"
        fi
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
            *) log_warn "bottom pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
        filename="bottom_${os_type}.tar.gz"
    fi

    url="https://github.com/ClementTsang/bottom/releases/download/${version}/${filename}"
    log "Downloading bottom $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "$BIN_DIR"
    chmod +x "$BIN_DIR/btm"
    
    # Install completions
    log "Downloading bottom completions..."
    local comp_url="https://github.com/ClementTsang/bottom/releases/download/${version}/completion.tar.gz"
    local comp_filename="btm_completion.tar.gz"
    local comp_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
    local tmp_comp_extract="/tmp/btm_comp_extract"
    
    mkdir -p "$comp_dir"
    mkdir -p "$tmp_comp_extract"
    curl -fsSL -L "$comp_url" -o "/tmp/$comp_filename"
    
    # Extract into the dedicated subdirectory
    tar -xzf "/tmp/$comp_filename" -C "$tmp_comp_extract"
    
    if [ -f "$tmp_comp_extract/btm.bash" ]; then
        cp "$tmp_comp_extract/btm.bash" "$comp_dir/btm"
        log "Installed bottom completion"
    fi
    
    rm -rf "$tmp_comp_extract" "/tmp/$filename" "/tmp/$comp_filename" 2>/dev/null || true
}

install_lazygit() {
    if command_exists lazygit; then
        log_skip "lazygit already installed: $(lazygit --version | head -1)"
        return 0
    fi

    log_step "Installing lazygit"

    local version arch os_type filename url
    version=$(curl -fsSL -I https://github.com/jesseduffield/lazygit/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r' | sed 's/^v//')
    [ -z "$version" ] && version="0.41.0"

    arch=$(uname -m)
    if is_macos; then
        if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
            os_type="darwin_arm64"
        else
            os_type="darwin_x86_64"
        fi
    else
        if [ "$arch" = "x86_64" ]; then
            os_type="linux_x86_64"
        else
            os_type="linux_arm64"
        fi
    fi

    filename="lazygit_${version}_${os_type}.tar.gz"
    url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/${filename}"
    
    log "Downloading lazygit $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    tar -xzf "/tmp/$filename" -C "$BIN_DIR" lazygit
    chmod +x "$BIN_DIR/lazygit"
    rm -f "/tmp/$filename"
}

install_yq() {
    if command_exists yq; then
        log_skip "yq already installed: $(yq --version | head -1)"
        return 0
    fi

    log_step "Installing yq"

    local version arch os_type filename url tag
    tag=$(curl -fsSL -I https://github.com/mikefarah/yq/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r')
    [ -z "$tag" ] && tag="v4.44.1"
    version=$(echo "$tag" | sed 's/^v//')

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="darwin_arm64" || os_type="darwin_amd64"
    else
        [ "$arch" = "x86_64" ] && os_type="linux_amd64" || os_type="linux_arm64"
    fi

    filename="yq_${os_type}.tar.gz"
    url="https://github.com/mikefarah/yq/releases/download/${tag}/${filename}"
    
    log "Downloading yq $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    tar -xzf "/tmp/$filename" -C "/tmp"
    # yq puts the binary as ./yq_<os_type> in the root or just yq
    local extracted_bin=$(find "/tmp" -maxdepth 1 -name "yq_${os_type}*" | head -1)
    if [ -n "$extracted_bin" ]; then
        cp "$extracted_bin" "$BIN_DIR/yq"
        chmod +x "$BIN_DIR/yq"
    fi
    rm -f "/tmp/$filename" "$extracted_bin"
}

install_btop() {
    if command_exists btop; then
        log_skip "btop already installed: $(btop --version | head -1)"
        return 0
    fi

    log_step "Installing btop"

    local version arch os_type filename url tag
    tag=$(curl -fsSL -I https://github.com/aristocratos/btop/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r')
    [ -z "$tag" ] && tag="v1.3.2"
    version=$(echo "$tag" | sed 's/^v//')

    arch=$(uname -m)
    if is_macos; then
        log_warn "btop does not provide macOS pre-built binaries. Use 'brew install btop'."
        return 0
    fi

    case "$arch" in
        x86_64) os_type="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
        *) log_warn "btop pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
    esac

    filename="btop-${os_type}.tbz"
    url="https://github.com/aristocratos/btop/releases/download/${tag}/${filename}"
    
    log "Downloading btop $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    mkdir -p "/tmp/btop_install"
    tar -xjf "/tmp/$filename" -C "/tmp/btop_install"
    # btop extracted contains bin/btop
    if [ -f "/tmp/btop_install/btop/bin/btop" ]; then
        cp "/tmp/btop_install/btop/bin/btop" "$BIN_DIR/btop"
        chmod +x "$BIN_DIR/btop"
    fi
    rm -rf "/tmp/$filename" "/tmp/btop_install"
}

install_yazi() {
    if command_exists yazi; then
        log_skip "yazi already installed: $(yazi --version | head -1)"
        return 0
    fi

    log_step "Installing yazi"

    local version arch os_type filename url tag
    tag=$(curl -fsSL -I https://github.com/sxyazi/yazi/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r')
    [ -z "$tag" ] && tag="v0.3.3"
    version=$(echo "$tag" | sed 's/^v//')

    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
            *) log_warn "yazi pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
    fi

    filename="yazi-${os_type}.zip"
    url="https://github.com/sxyazi/yazi/releases/download/${tag}/${filename}"
    
    log "Downloading yazi $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    mkdir -p "/tmp/yazi_install"
    extract_zip "/tmp/$filename" "/tmp/yazi_install"
    # yazi extracted contains yazi-<os_type>/yazi
    local extracted_dir=$(find "/tmp/yazi_install" -maxdepth 1 -name "yazi-*" -type d | head -1)
    if [ -n "$extracted_dir" ]; then
        cp "$extracted_dir/yazi" "$BIN_DIR/yazi"
        #[ -f "$extracted_dir/ya" ] && cp "$extracted_dir/ya" "$BIN_DIR/ya" # ya is the CLI companion
        chmod +x "$BIN_DIR/yazi"
    fi
    rm -rf "/tmp/$filename" "/tmp/yazi_install"
}

install_direnv() {
    if command_exists direnv; then
        log_skip "direnv already installed: $(direnv version)"
        return 0
    fi

    log_step "Installing direnv"

    local arch os_type filename url
    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="darwin-arm64" || os_type="darwin-amd64"
    else
        [ "$arch" = "x86_64" ] && os_type="linux-amd64" || os_type="linux-arm64"
    fi

    filename="direnv.${os_type}"
    url="https://github.com/direnv/direnv/releases/latest/download/${filename}"
    
    log "Downloading direnv..."
    curl -fsSL -L "$url" -o "$BIN_DIR/direnv"
    chmod +x "$BIN_DIR/direnv"
}

install_tldr() {
    if command_exists tldr; then
        log_skip "tldr (tealdeer) already installed: $(tldr --version)"
        return 0
    fi

    log_step "Installing tealdeer (tldr)"

    local arch os_type filename url
    arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="macos-aarch64" || os_type="macos-x86_64"
    else
        [ "$arch" = "x86_64" ] && os_type="linux-x86_64-musl" || os_type="linux-armv7-musleabihf"
    fi

    filename="tealdeer-${os_type}"
    url="https://github.com/dbrgn/tealdeer/releases/latest/download/${filename}"
    
    log "Downloading tealdeer..."
    curl -fsSL -L "$url" -o "$BIN_DIR/tldr"
    chmod +x "$BIN_DIR/tldr"
    
    # Initialize cache
    $BIN_DIR/tldr --update 2>/dev/null || true
}

install_dust() {
    if command_exists dust; then
        log_skip "dust already installed: $(dust --version)"
        return 0
    fi

    log_step "Installing dust"

    local version arch os_type filename url tag
    tag=$(curl -fsSL -I https://github.com/bootandy/dust/releases/latest | grep -i "location:" | awk -F/ '{print $NF}' | tr -d '\r')
    [ -z "$tag" ] && tag="v1.1.1"
    version=$(echo "$tag" | sed 's/^v//')

    arch=$(uname -m)
    if is_macos; then
        # dust provides x86_64-apple-darwin which works on arm64 via Rosetta
        os_type="x86_64-apple-darwin"
    else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
            *) log_warn "dust pre-built binaries not found for $arch Linux. Skipping."; return 0 ;;
        esac
    fi

    filename="dust-${tag}-${os_type}.tar.gz"
    url="https://github.com/bootandy/dust/releases/download/${tag}/${filename}"
    
    log "Downloading dust..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    tar -xzf "/tmp/$filename" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "dust-*" -type d | head -1)
    if [ -n "$extracted_dir" ]; then
        cp "$extracted_dir/dust" "$BIN_DIR/dust"
        chmod +x "$BIN_DIR/dust"
    fi
    rm -rf "/tmp/$filename" "$extracted_dir"
}

install_httpie() {
    if command_exists http; then
        log_skip "httpie already installed"
        return 0
    fi

    log_step "Installing httpie via uv"
    if command_exists uv; then
        uv tool install httpie 2>/dev/null || log_warn "uv tool install httpie failed"
    else
        log_warn "uv not found, skipping httpie installation"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    ensure_bin_dir
    
    # Export PATH just in case
    export PATH="$BIN_DIR:$PATH"

    if is_macos && command_exists brew; then
        log_step "Homebrew detected, using it for tools"
        brew install \
            gh 1password-cli zellij jq neovim uv \
            ripgrep fd bat eza fzf zoxide git-delta starship bottom lazygit \
            yq btop yazi direnv tealdeer dust httpie \
            2>/dev/null || true
    else
        install_uv
        install_gh
        install_op
        install_zellij
        install_jq
        install_nvim
        install_rg
        install_fd
        install_bat
        install_eza
        install_fzf
        install_zoxide
        install_delta
        install_starship
        install_bottom
        install_lazygit
        install_yq
        install_btop
        install_yazi
        install_direnv
        install_tldr
        install_dust
        install_httpie
    fi

    generate_completions
}

generate_completions() {
    log_step "Generating shell completions"
    local comp_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
    mkdir -p "$comp_dir"

    if command_exists gh; then
        gh completion -s bash > "$comp_dir/gh"
        log "Generated gh completion"
    fi

    if command_exists op; then
        op completion bash > "$comp_dir/op"
        log "Generated op completion"
    fi

    if command_exists zellij; then
        zellij setup --generate-completion bash > "$comp_dir/zellij"
        log "Generated zellij completion"
    fi

    if command_exists uv; then
        uv generate-shell-completion bash > "$comp_dir/uv"
        log "Generated uv completion"
    fi

    if command_exists starship; then
        starship completions bash > "$comp_dir/starship"
        log "Generated starship completion"
    fi

    if command_exists rg; then
        rg --generate complete-bash > "$comp_dir/rg" 2>/dev/null && log "Generated rg completion"
    fi

    if command_exists fd; then
        fd --gen-completions bash > "$comp_dir/fd" 2>/dev/null && log "Generated fd completion"
    fi
}

main "$@"
