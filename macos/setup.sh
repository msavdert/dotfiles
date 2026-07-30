#!/usr/bin/env bash
# =============================================================================
# macOS setup - provisions the THIN CLIENT half of this repo
# =============================================================================
# Installs the Brewfile (removing anything not in it), installs the four host
# CLI tools from configs/mise/macos.toml, and links the small set of configs the
# laptop actually needs.
#
# It deliberately does NOT install neovim, zellij, language runtimes or the
# kubernetes tooling. Those live in the devbox image. See docs/01-macos-setup.md.
#
# Usage:
#   ./macos/setup.sh              # full run
#   ./macos/setup.sh --links-only # just refresh symlinks
#   DRY_RUN=1 ./macos/setup.sh    # show what would happen
# =============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_DIR
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly BACKUP_ROOT="$HOME/.dotfiles-backups"
readonly DRY_RUN="${DRY_RUN:-}"

BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR

info()  { printf '\033[0;32m[ok]\033[0m   %s\n' "$*"; }
warn()  { printf '\033[0;33m[warn]\033[0m %s\n' "$*"; }
step()  { printf '\n\033[0;34m==>\033[0m %s\n' "$*"; }
die()   { printf '\033[0;31m[err]\033[0m  %s\n' "$*" >&2; exit 1; }

run() {
    if [[ -n "$DRY_RUN" ]]; then
        printf '       would run: %s\n' "$*"
    else
        "$@"
    fi
}

# -----------------------------------------------------------------------------
require_macos() {
    [[ "$(uname -s)" == "Darwin" ]] || die "this script is macOS-only; the Linux side is the devbox image (see docs/02-devbox-image.md)"
}

install_homebrew() {
    step "Homebrew"
    if command -v brew >/dev/null 2>&1; then
        info "already installed ($(brew --version | head -1))"
        return
    fi
    [[ -n "$DRY_RUN" ]] && { warn "would install Homebrew"; return; }
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon puts brew outside the default PATH.
    [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
}

apply_brewfile() {
    step "Brewfile (declarative: --cleanup removes anything not listed)"
    command -v brew >/dev/null 2>&1 || { warn "brew missing, skipping"; return; }

    # Show the diff before destroying anything.
    if ! brew bundle check --file="$REPO_DIR/macos/Brewfile" >/dev/null 2>&1; then
        brew bundle check --file="$REPO_DIR/macos/Brewfile" || true
    fi

    if [[ -n "$DRY_RUN" ]]; then
        brew bundle --file="$REPO_DIR/macos/Brewfile" --cleanup --force --no-upgrade --verbose --dry-run || true
        return
    fi

    brew bundle --file="$REPO_DIR/macos/Brewfile"
    # --cleanup without --force only PRINTS what it would remove. That is the
    # safe default here: read the list, then re-run with CLEANUP=1 to apply.
    if [[ "${CLEANUP:-}" == "1" ]]; then
        brew bundle cleanup --file="$REPO_DIR/macos/Brewfile" --force
        info "removed packages not present in the Brewfile"
    else
        brew bundle cleanup --file="$REPO_DIR/macos/Brewfile" || true
        warn "the above would be REMOVED. Re-run with CLEANUP=1 to apply."
    fi
}

# -----------------------------------------------------------------------------
# Symlinks
#
# Note what is missing on purpose: ~/.config/nvim and ~/.config/zellij. Editing
# and multiplexing happen inside the devbox, not on the laptop.
link_configs() {
    step "Symlinks"

    # Create only PARENT directories. Creating the link targets themselves (the
    # old script did `mkdir -p ~/.config/nvim` right before linking it)
    # guarantees a pointless backup dance on every fresh machine.
    run mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/mise" "$HOME/.ssh/sockets"
    run chmod 700 "$HOME/.ssh"

    local pairs=(
        "$REPO_DIR/configs/zsh/.zshenv:$HOME/.zshenv"
        "$REPO_DIR/configs/zsh/.zshrc:$HOME/.zshrc"
        "$REPO_DIR/configs/git/config:$HOME/.gitconfig"
        "$REPO_DIR/configs/starship.toml:$CONFIG_DIR/starship.toml"
        "$REPO_DIR/configs/op-env:$CONFIG_DIR/op-env"
        "$REPO_DIR/configs/mise/macos.toml:$CONFIG_DIR/mise/config.toml"
        "$REPO_DIR/configs/ssh/config:$HOME/.ssh/config"
        "$REPO_DIR/configs/ssh/config.macos:$HOME/.ssh/config.macos"
    )

    local pair src dst tilde='~'
    for pair in "${pairs[@]}"; do
        src="${pair%%:*}"
        dst="${pair##*:}"

        if [[ ! -e "$src" ]]; then
            warn "missing source, skipped: $src"
            continue
        fi

        if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
            info "already linked: ${dst/#$HOME/$tilde}"
            continue
        fi

        if [[ -e "$dst" || -L "$dst" ]]; then
            run mkdir -p "$BACKUP_DIR"
            run mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
            warn "backed up existing ${dst/#$HOME/$tilde} -> ${BACKUP_DIR/#$HOME/$tilde}/"
        fi

        run ln -sfn "$src" "$dst"
        info "linked ${dst/#$HOME/$tilde}"
    done

    [[ -d "$BACKUP_DIR" ]] && warn "review and delete $BACKUP_DIR when you are happy"
    return 0
}

install_mise_tools() {
    step "Host CLI tools (configs/mise/macos.toml)"
    if ! command -v mise >/dev/null 2>&1; then
        warn "mise not on PATH yet - open a new shell and re-run"
        return
    fi
    run mise install -y
    run mise prune --yes
}

check_1password_agent() {
    step "1Password SSH agent"
    local sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    if [[ -S "$sock" ]]; then
        info "agent socket is live; ~/.ssh/config.macos points IdentityAgent at it"
    else
        warn "agent socket not found."
        warn "Enable it in: 1Password -> Settings -> Developer -> 'Use the SSH agent'"
        warn "Until then, ssh will fall back to on-disk keys."
    fi
}

summary() {
    cat <<'EOF'

-------------------------------------------------------------------------------
macOS client is provisioned.

Next:
  1. exec zsh                      reload the shell
  2. op signin                     unlock 1Password CLI
  3. ssh dev                       connect to the devbox on the VPS
                                   (add the Host block from docs/03-vps-deployment.md
                                    to ~/.ssh/config.local first)

Run the devbox locally instead:
  docker run -it --rm ghcr.io/msavdert/devbox:latest zsh

Docs: docs/README.md
-------------------------------------------------------------------------------
EOF
}

main() {
    require_macos

    if [[ "${1:-}" == "--links-only" ]]; then
        link_configs
        summary
        return
    fi

    install_homebrew
    apply_brewfile
    link_configs
    install_mise_tools
    check_1password_agent
    summary
}

main "$@"
