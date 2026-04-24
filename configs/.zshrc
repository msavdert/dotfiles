# ==============================================================================
# MSAVDERT ZSH CONFIGURATION (MINIMAL & FAST)
# ==============================================================================

# --- 1. Language & Locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- 2. Terminal & Compatibility ---
export TERM="xterm-256color"
export COLORTERM="truecolor"

# --- 3. PATH Setup ---
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# --- 4. SSH Agent Management ---
# Use a fixed socket to prevent multiple agents and stale connections
export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"
if [ ! -S "$SSH_AUTH_SOCK" ]; then
    # Start a new agent if the socket doesn't exist
    eval $(ssh-agent -s -a "$SSH_AUTH_SOCK") > /dev/null
else
    # Check if the existing agent is actually responding
    ssh-add -l > /dev/null 2>&1
    if [ $? -eq 2 ]; then
        # Agent is dead, cleanup and restart
        rm -f "$SSH_AUTH_SOCK"
        eval $(ssh-agent -s -a "$SSH_AUTH_SOCK") > /dev/null
    fi
fi

# --- 5. Secret Wrappers ---
export OP_ENV_FILE="$HOME/.config/personal.env"

run_with_secrets() {
    if [[ -f "$OP_ENV_FILE" ]] && command -v op >/dev/null; then
        op run --no-masking --env-file="$OP_ENV_FILE" -- "$@"
    else
        "$@"
    fi
}

# --- 5. Completion Engine (Standard) ---
autoload -Uz compinit
compinit

# Basic completion settings
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion

# --- 6. History & Options ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# --- 7. Aliases ---
alias v='nvim'
#alias vi='nvim'
alias vim='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -p'

# Modern Replacements
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias ping='gping'
alias msync='mise run sync && exec zsh'
alias g='run_with_secrets git'
alias lg='run_with_secrets lazygit'
alias gh='run_with_secrets gh'
alias claude='run_with_secrets claude'
alias gemini='run_with_secrets gemini'

# --- 8. Tool Integrations ---

# Mise
if command -v mise >/dev/null; then
    eval "$(mise activate zsh)"
    eval "$(mise completion zsh)"
fi

# Zoxide
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Starship (Prompt)
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
fi

# 1Password CLI Completion
if command -v op >/dev/null; then
    eval "$(op completion zsh)"
    compdef _op op
fi

# GitHub CLI Completion
if command -v gh >/dev/null; then
    eval "$(gh completion -s zsh)"
fi

# FZF (Standard Integration for Ctrl+R)
if command -v fzf >/dev/null; then
    source <(fzf --zsh)
fi

# --- 9. Custom Functions ---

# Interactive SSH host selector
ssh() {
  if [ $# -eq 0 ]; then
    local host=$(grep -iE "^host " ~/.ssh/config 2>/dev/null | awk '{print $2}' | grep -v '*' | fzf --height 40% --reverse --border --prompt="🚀 SSH Host > " --preview 'dig {}')
    if [ -n "$host" ]; then
      echo "Connecting to $host..."
      command ssh "$host"
    fi
  else
    command ssh "$@"
  fi
}
