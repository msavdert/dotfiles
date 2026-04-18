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

# Helper to extract ZIP files using Python (managed via uv)
extract_zip() {
    local zip_file="$1"
    local dest_dir="$2"
    local entry="${3:-}"

    if [ -n "$entry" ]; then
        uv run python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extract(sys.argv[3], sys.argv[2])" "$zip_file" "$dest_dir" "$entry"
    else
        uv run python -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip_file" "$dest_dir"
    fi
}

# =============================================================================
# Unified Installer Logic
# =============================================================================

# Get latest version from GitHub
get_latest_version() {
    local repo="$1"
    local version=""
    
    if command_exists gh; then
        version=$(gh release view -R "$repo" --json tagName -q .tagName 2>/dev/null | sed 's/^v//' || echo "")
    fi
    
    if [ -z "$version" ]; then
        # Try API first, then fall back to location header
        version=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//' || echo "")
    fi

    if [ -z "$version" ] || [ "$version" = "latest" ]; then
        version=$(curl -fsSL -I "https://github.com/$repo/releases/latest" 2>/dev/null | grep -i "^location:" | head -n 1 | awk -F/ '{print $NF}' | tr -d '\r ' | sed 's/^v//' || echo "")
    fi
    
    echo "$version"
}

# Install completions for a tool
install_completion() {
    local tool="$1"
    local comp_dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
    mkdir -p "$comp_dir"

    case "$tool" in
        gh) gh completion -s bash > "$comp_dir/gh" 2>/dev/null || true ;;
        uv) uv generate-shell-completion bash > "$comp_dir/uv" 2>/dev/null || true ;;
        zellij) zellij setup --generate-completion bash > "$comp_dir/zellij" 2>/dev/null || true ;;
        fzf) fzf --bash > "$comp_dir/fzf" 2>/dev/null || true ;;
        starship) starship completions bash > "$comp_dir/starship" 2>/dev/null || true ;;
        yq) yq shell-completion bash > "$comp_dir/yq" 2>/dev/null || true ;;
        bun) bun completions bash > "$comp_dir/bun" 2>/dev/null || true ;;
    esac
}

# Generic GitHub binary installer
github_tool_install() {
    local repo="$1"
    local bin_name="$2"
    local version_cmd="${3:-$bin_name --version}"
    local filename_func="$4"
    local extract_func="$5"
    local version_override_func="${6:-}"

    if command_exists "$bin_name"; then
        log_skip "$bin_name already installed: $($version_cmd 2>&1 | head -1)"
        install_completion "$bin_name"
        return 0
    fi

    log_step "Installing $bin_name"
    local version
    if [ -n "$version_override_func" ]; then
        version=$($version_override_func)
    else
        version=$(get_latest_version "$repo")
    fi
    
    [ -z "$version" ] && { log_error "Could not detect version for $bin_name"; return 1; }

    local filename=$($filename_func "$version")
    local url="https://github.com/$repo/releases/download/v${version}/${filename}"
    
    # Special case for some repos that don't prefix with v
    if ! curl -fsSL -I "$url" >/dev/null 2>&1; then
        url="https://github.com/$repo/releases/download/${version}/${filename}"
    fi

    log "Downloading $bin_name $version..."
    curl -fsSL -L "$url" -o "/tmp/$filename"
    
    $extract_func "/tmp/$filename" "$version"
    
    chmod +x "$BIN_DIR/$bin_name"
    install_completion "$bin_name"
    rm -f "/tmp/$filename"
}

# =============================================================================
# Binary Installers
# =============================================================================

# Zellij
zellij_filename() {
    local arch=$(uname -m)
    [ "$arch" = "arm64" ] && arch="aarch64"
    if is_macos; then
        echo "zellij-$arch-apple-darwin.tar.gz"
    else
        echo "zellij-$arch-unknown-linux-musl.tar.gz"
    fi
}
zellij_extract() { tar -xzf "$1" -C "$BIN_DIR"; }

install_zellij() {
    github_tool_install "zellij-org/zellij" "zellij" "zellij --version" zellij_filename zellij_extract
}

# GitHub CLI
gh_filename() {
    local version="$1"
    if is_macos; then
        local arch=$(uname -m)
        [ "$arch" = "arm64" ] && arch="arm64" || arch="amd64"
        echo "gh_${version}_macOS_${arch}.zip"
    else
        echo "gh_${version}_linux_$(uname_m_to_gh_linux).tar.gz"
    fi
}
gh_extract() {
    local file="$1" version="$2"
    if is_macos; then
        mkdir -p "/tmp/gh_install"
        extract_zip "$file" "/tmp/gh_install"
        find "/tmp/gh_install" -name "gh" -exec cp {} "$BIN_DIR/" \;
        rm -rf "/tmp/gh_install"
    else
        local arch=$(uname_m_to_gh_linux)
        tar -xzf "$file" -C "/tmp"
        cp "/tmp/gh_${version}_linux_${arch}/bin/gh" "$BIN_DIR/"
        rm -rf "/tmp/gh_${version}_linux_${arch}"
    fi
}
install_gh() {
    github_tool_install "cli/cli" "gh" "gh --version" gh_filename gh_extract
}


uname_m_to_gh_linux() {
    case "$(uname -m)" in
        x86_64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) echo "386" ;;
    esac
}


# 1Password CLI (Special versioning from update page)
op_version() {
    if command_exists python3; then
        python3 -c "import urllib.request, re; content = urllib.request.urlopen('https://app-updates.agilebits.com/product_history/CLI2').read().decode(); links = re.findall(r'v([0-9.]+)/op_linux', content); print(links[0] if links else '2.33.1')" 2>/dev/null || echo "2.33.1"
    else
        echo "2.33.1"
    fi
}
op_filename() {
    local version="$1" arch=$(uname -m)
    [ "$arch" = "x86_64" ] && arch="amd64" || arch="arm64"
    if is_macos; then echo "op_darwin_${arch}_v${version}.zip"; else echo "op_linux_${arch}_v${version}.zip"; fi
}
op_extract() { extract_zip "$1" "$BIN_DIR" "op"; }

install_op() {
    if command_exists op; then
        log_skip "op already installed: $(op --version 2>&1 | head -1)"
        install_completion "op"
        return 0
    fi

    log_step "Installing op"
    local version=$(op_version)
    local filename=$(op_filename "$version")
    local url="https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/$filename"
    
    log "Downloading op $version..."
    curl -fsSL "$url" -o "/tmp/$filename"
    op_extract "/tmp/$filename" "$version"
    
    chmod +x "$BIN_DIR/op"
    install_completion "op"
    rm -f "/tmp/$filename"
}

# jq
jq_filename() {
    local version="$1" arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && echo "jq-macos-arm64" || echo "jq-macos-amd64"
    else
        [ "$arch" = "x86_64" ] && arch="amd64" || arch="arm64"
        echo "jq-linux-${arch}"
    fi
}
jq_extract() { cp "$1" "$BIN_DIR/jq"; }

install_jq() {
    github_tool_install "jqlang/jq" "jq" "jq --version" jq_filename jq_extract
}


# Neovim
nvim_filename() {
    local arch=$(uname -m)
    if is_macos; then
        [ "$arch" = "arm64" ] && echo "nvim-macos-arm64.tar.gz" || echo "nvim-macos-x86_64.tar.gz"
    else
        case "$arch" in
            x86_64) echo "nvim-linux-x86_64.tar.gz" ;;
            aarch64|arm64) echo "nvim-linux-arm64.tar.gz" ;;
        esac
    fi
}
nvim_extract() {
    mkdir -p "$HOME/.local/apps"
    rm -rf "$HOME/.local/apps/nvim"
    tar -xzf "$1" -C "$HOME/.local/apps"
    local extracted_dir=$(find "$HOME/.local/apps" -maxdepth 1 -name "nvim-*" -type d | head -1)
    mv "$extracted_dir" "$HOME/.local/apps/nvim"
    ln -sf "$HOME/.local/apps/nvim/bin/nvim" "$BIN_DIR/nvim"
}

install_nvim() {
    # Check for GLIBC version (min 2.32 required for latest nvim binaries)
    if ! is_macos; then
        local glibc_version=$(ldd --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
        if [ "$(echo "$glibc_version < 2.32" | bc -l 2>/dev/null || awk "BEGIN {print ($glibc_version < 2.32)}")" -eq 1 ]; then
            log_warn "System GLIBC ($glibc_version) is too old for latest Neovim. Skipping."
            return 0
        fi
    fi
    github_tool_install "neovim/neovim" "nvim" "nvim --version" nvim_filename nvim_extract
}


# uv
uv_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"; else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-gnu" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-gnu" ;;
        esac
    fi
    echo "uv-${os_type}.tar.gz"
}
uv_extract() {
    mkdir -p "/tmp/uv_install"
    tar -xzf "$1" -C "/tmp/uv_install"
    local extracted_dir=$(find "/tmp/uv_install" -maxdepth 1 -name "uv-*" -type d | head -1)
    cp "$extracted_dir/uv" "$BIN_DIR/uv"
    cp "$extracted_dir/uvx" "$BIN_DIR/uvx"
    rm -rf "/tmp/uv_install"
    chmod +x "$BIN_DIR/uvx"
}
install_uv() {
    github_tool_install "astral-sh/uv" "uv" "uv --version" uv_filename uv_extract
}

# ripgrep (rg)
rg_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"; else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-gnu" ;;
        esac
    fi
    echo "ripgrep-${version}-${os_type}.tar.gz"
}
rg_extract() {
    tar -xzf "$1" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "ripgrep-*" -type d | head -1)
    cp "$extracted_dir/rg" "$BIN_DIR/"
    rm -rf "$extracted_dir"
}
install_rg() {
    github_tool_install "BurntSushi/ripgrep" "rg" "rg --version" rg_filename rg_extract
}

# fd
fd_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"; else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
        esac
    fi
    echo "fd-v${version}-${os_type}.tar.gz"
}
fd_extract() {
    tar -xzf "$1" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "fd-v*" -type d | head -1)
    cp "$extracted_dir/fd" "$BIN_DIR/"
    rm -rf "$extracted_dir"
}
install_fd() {
    github_tool_install "sharkdp/fd" "fd" "fd --version" fd_filename fd_extract
}


# bat
bat_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"; else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
        esac
    fi
    echo "bat-v${version}-${os_type}.tar.gz"
}
bat_extract() {
    tar -xzf "$1" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "bat-v*" -type d | head -1)
    cp "$extracted_dir/bat" "$BIN_DIR/"
    rm -rf "$extracted_dir"
}
install_bat() {
    github_tool_install "sharkdp/bat" "bat" "bat --version" bat_filename bat_extract
}

# eza
eza_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then echo "eza_x86_64-apple-darwin.zip"; else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-gnu" ;;
        esac
        echo "eza_${os_type}.tar.gz"
    fi
}
eza_extract() {
    local file="$1" version="$2"
    if [[ "$file" == *.zip ]]; then extract_zip "$file" "$BIN_DIR" "eza"; else tar -xzf "$file" -C "$BIN_DIR"; fi
}
install_eza() {
    github_tool_install "eza-community/eza" "eza" "eza --version" eza_filename eza_extract
}

# fzf
fzf_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="darwin_arm64" || os_type="darwin_amd64"; else
        [ "$arch" = "x86_64" ] && os_type="linux_amd64" || os_type="linux_arm64"
    fi
    echo "fzf-${version}-${os_type}.tar.gz"
}
fzf_extract() { tar -xzf "$1" -C "$BIN_DIR"; }

install_fzf() {
    github_tool_install "junegunn/fzf" "fzf" "fzf --version" fzf_filename fzf_extract
}


# zoxide
zoxide_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"; else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
        esac
    fi
    echo "zoxide-${version}-${os_type}.tar.gz"
}
zoxide_extract() { tar -xzf "$1" -C "$BIN_DIR"; }

install_zoxide() {
    github_tool_install "ajeetdsouza/zoxide" "zoxide" "zoxide --version" zoxide_filename zoxide_extract
}

# delta
delta_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"; else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-gnu" ;;
        esac
    fi
    echo "delta-${version}-${os_type}.tar.gz"
}
delta_extract() {
    tar -xzf "$1" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "delta-${version}-*" -type d | head -1)
    cp "$extracted_dir/delta" "$BIN_DIR/"
    rm -rf "$extracted_dir"
}
install_delta() {
    github_tool_install "dandavison/delta" "delta" "delta --version" delta_filename delta_extract
}

# starship
starship_filename() {
    local arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"; else
        case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
        esac
    fi
    echo "starship-${os_type}.tar.gz"
}
starship_extract() { tar -xzf "$1" -C "$BIN_DIR"; }

install_starship() {
    github_tool_install "starship/starship" "starship" "starship --version" starship_filename starship_extract
}


# lazygit
lazygit_filename() {
    local version="$1" arch=$(uname -m)
    if is_macos; then [ "$arch" = "arm64" ] && echo "lazygit_${version}_darwin_arm64.tar.gz" || echo "lazygit_${version}_darwin_x86_64.tar.gz"
    else [ "$arch" = "x86_64" ] && echo "lazygit_${version}_linux_x86_64.tar.gz" || echo "lazygit_${version}_linux_arm64.tar.gz"; fi
}
lazygit_extract() { tar -xzf "$1" -C "$BIN_DIR" lazygit; }

install_lazygit() {
    github_tool_install "jesseduffield/lazygit" "lazygit" "lazygit --version" lazygit_filename lazygit_extract
}

# yq
yq_filename() {
    local arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="darwin_arm64" || os_type="darwin_amd64"; else
        [ "$arch" = "x86_64" ] && os_type="linux_amd64" || os_type="linux_arm64"; fi
    echo "yq_${os_type}.tar.gz"
}
yq_extract() {
    local arch=$(uname -m)
    if is_macos; then [ "$arch" = "arm64" ] && arch="darwin_arm64" || arch="darwin_amd64"; else
        [ "$arch" = "x86_64" ] && arch="linux_amd64" || arch="linux_arm64"; fi
    tar -xzf "$1" -C "/tmp"
    local bin=$(find "/tmp" -maxdepth 1 -name "yq_${arch}*" | head -1)
    [ -n "$bin" ] && cp "$bin" "$BIN_DIR/yq" && rm "$bin"
}
install_yq() {
    github_tool_install "mikefarah/yq" "yq" "yq --version" yq_filename yq_extract
}

# btop
btop_filename() {
    local arch=$(uname -m)
    if is_macos; then echo "btop-x86_64-apple-darwin.tbz"; else
        case "$arch" in
            x86_64) echo "btop-x86_64-unknown-linux-musl.tbz" ;;
            aarch64|arm64) echo "btop-aarch64-unknown-linux-musl.tbz" ;;
        esac
    fi
}
# Helper to extract .tar.bz2 (tbz) files using Python (managed via uv)
extract_tar_bz2() {
    local tar_file="$1"
    local dest_dir="$2"

    uv run python -c "import tarfile,sys; t=tarfile.open(sys.argv[1], 'r:bz2'); t.extractall(sys.argv[2], filter='fully_trusted') if hasattr(tarfile, 'data_filter') else t.extractall(sys.argv[2])" "$tar_file" "$dest_dir"
}
btop_extract() {
    # btop uses .tbz
    extract_tar_bz2 "$1" "/tmp"
    cp "/tmp/btop/bin/btop" "$BIN_DIR/btop"
    rm -rf "/tmp/btop"
}
install_btop() {
    github_tool_install "aristocratos/btop" "btop" "btop --version" btop_filename btop_extract
}


# yazi
yazi_filename() {
    local arch=$(uname -m) os_type
    if is_macos; then [ "$arch" = "arm64" ] && os_type="aarch64-apple-darwin" || os_type="x86_64-apple-darwin"
    else case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
        esac
    fi
    echo "yazi-${os_type}.zip"
}
yazi_extract() {
    mkdir -p "/tmp/yazi_install"
    extract_zip "$1" "/tmp/yazi_install"
    local extracted_dir=$(find "/tmp/yazi_install" -maxdepth 1 -name "yazi-*" -type d | head -1)
    cp "$extracted_dir/yazi" "$BIN_DIR/yazi"
    rm -rf "/tmp/yazi_install"
}
install_yazi() {
    github_tool_install "sxyazi/yazi" "yazi" "yazi --version" yazi_filename yazi_extract
}



# dust
dust_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then os_type="x86_64-apple-darwin"
    else case "$arch" in
            x86_64) os_type="x86_64-unknown-linux-musl" ;;
            aarch64|arm64) os_type="aarch64-unknown-linux-musl" ;;
        esac
    fi
    echo "dust-v${version}-${os_type}.tar.gz"
}
dust_extract() {
    tar -xzf "$1" -C "/tmp"
    local extracted_dir=$(find "/tmp" -maxdepth 1 -name "dust-*" -type d | head -1)
    cp "$extracted_dir/dust" "$BIN_DIR/dust"
    rm -rf "$extracted_dir"
}
install_dust() {
    github_tool_install "bootandy/dust" "dust" "dust --version" dust_filename dust_extract
}

# Bun (All-in-one JavaScript runtime & manager)
bun_filename() {
    local version="$1" arch=$(uname -m) os_type
    if is_macos; then
        [ "$arch" = "arm64" ] && os_type="darwin-aarch64" || os_type="darwin-x64"
    else
        [ "$arch" = "x86_64" ] && os_type="linux-x64" || os_type="linux-aarch64"
    fi
    echo "bun-$os_type.zip"
}

bun_extract() {
    local file="$1"
    mkdir -p "/tmp/bun_install"
    extract_zip "$file" "/tmp/bun_install"
    local bin_source=$(find "/tmp/bun_install" -name "bun" -type f | head -1)
    cp "$bin_source" "$BIN_DIR/bun"
    ln -sf "$BIN_DIR/bun" "$BIN_DIR/bunx"
    ln -sf "$BIN_DIR/bun" "$BIN_DIR/node"
    rm -rf "/tmp/bun_install"
}

install_bun() {
    github_tool_install "oven-sh/bun" "bun" "bun --version" bun_filename bun_extract
}

# httpie (uv-based)
install_httpie() {
    if command_exists http; then return 0; fi
    log_step "Installing httpie via uv"
    command_exists uv && (uv tool install httpie 2>/dev/null || true)
}

# =============================================================================
# Main
# =============================================================================

main() {
    ensure_bin_dir
    export PATH="$BIN_DIR:$PATH"

    if is_macos && command_exists brew; then
        log_step "Homebrew detected, using it for tools"
        brew install \
            gh 1password-cli zellij jq neovim uv \
            ripgrep fd bat eza fzf zoxide git-delta starship lazygit \
            yq btop yazi dust httpie \
            2>/dev/null || true
    else
        # Preferred installation order
        local tools=(uv gh op zellij jq nvim rg fd bat eza fzf zoxide delta starship lazygit yq btop yazi dust httpie bun)
        for tool in "${tools[@]}"; do
            "install_$tool"
        done
    fi

    log_step "Installation complete."
}

main "$@"
