# =============================================================================
# .zshenv - sourced by EVERY zsh (interactive, non-interactive, scripts)
# =============================================================================
# Only things that must exist for `ssh devbox 'some-command'` and for editors
# that spawn a non-login shell. Keep it fast: no subprocesses, no network.
# Interactive-only setup belongs in .zshrc.
# =============================================================================

# --- Locale ---
# Set LANG only, and only when the environment has not already chosen one.
# Exporting LC_ALL unconditionally overrides every per-category setting and is
# almost never what you want.
: "${LANG:=en_US.UTF-8}"
export LANG

# --- PATH ---
# mise shims make tools resolvable in NON-interactive shells (scripts, ssh
# one-liners, editors). Interactive shells additionally run `mise activate`
# in .zshrc, which shadows the shims with the faster direct paths.
typeset -U path                                   # de-duplicate automatically
path=("$HOME/.local/bin" "$HOME/.local/share/mise/shims" $path)
export PATH

# --- Defaults ---
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-FRX"

# --- XDG & Tool Configs ---
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

