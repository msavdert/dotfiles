# --- Mise-en-place ---
if [ -f "$HOME/.local/bin/mise" ]; then
    export PATH="$HOME/.local/bin:$PATH"
    eval "$($HOME/.local/bin/mise activate zsh)"
elif command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# --- Starship Prompt ---
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# --- Zoxide (Smart cd) ---
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
