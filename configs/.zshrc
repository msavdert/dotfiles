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
# Editor
alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -p'

# Tools
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias ping='gping'
alias tldr='tlrc'
alias g='git'
alias lg='lazygit'

# --- History & Navigation ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS

# --- Completion ---
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion

# FZF integration
if command -v fzf >/dev/null; then
    source <(fzf --zsh)
fi

# Zoxide integration
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Starship integration
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
fi

# Keybindings for history search
# Use Up/Down arrows to search history based on current input
# Note: These sequences might vary by terminal, but these are standard
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey -e

