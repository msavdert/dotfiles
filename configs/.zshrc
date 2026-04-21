# --- Language & Locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- PATH Setup ---
# Ensure mise binaries and shims are always in PATH
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# --- Mise Activation ---
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# --- Tools Initialization ---
# Initialize tools after mise shims are in PATH
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# --- Aliases ---
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias cat='bat --style=plain'
alias g='git'
alias lg='lazygit'

# --- 1Password Helper ---
if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
    export OP_SESSION_my="$(op signin --raw)"
fi

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# --- Keybindings ---
bindkey -e
