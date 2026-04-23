# ==============================================================================
# MSAVDERT ZSH CONFIGURATION
# ==============================================================================

# --- 1. Language & Locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- 2. Terminal & Compatibility ---
# Fix 'unknown terminal type' errors for Ghostty users on remote servers
if [[ "$TERM" == "xterm-ghostty" ]]; then
  export TERM=xterm-256color
fi

# --- 3. PATH Setup ---
# Ensure mise binaries and shims are always in PATH
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# --- 4. Zsh Plugin Manager (Minimal) ---
zsh_add_plugin() {
    local plugin_name=$(basename "$1")
    local plugin_dir="$HOME/.zsh/plugins/$plugin_name"
    if [ ! -d "$plugin_dir" ]; then
        echo "📥 Downloading zsh plugin: $plugin_name..."
        mkdir -p "$HOME/.zsh/plugins"
        git clone --depth 1 "$1" "$plugin_dir" > /dev/null
    fi
    if [ -f "$plugin_dir/$plugin_name.plugin.zsh" ]; then
        source "$plugin_dir/$plugin_name.plugin.zsh"
    elif [ -f "$plugin_dir/$plugin_name.zsh" ]; then
        source "$plugin_dir/$plugin_name.zsh"
    fi
}

# --- 5. Secret Wrappers (Must be before Aliases) ---
# 1Password Environment Map Path
export OP_ENV_FILE="$HOME/.config/op/personal.env"

# Secure Secret Wrapper
# Runs a command with 1Password secrets injected if the env file exists
run_with_secrets() {
    if [[ -f "$OP_ENV_FILE" ]] && command -v op >/dev/null; then
        op run --env-file="$OP_ENV_FILE" -- "$@"
    else
        "$@"
    fi
}

# --- 6. Plugins (Early Load) ---
# fzf-tab must be loaded BEFORE compinit
zsh_add_plugin "https://github.com/Aloxaf/fzf-tab"

# --- 7. Completion Engine & Styling ---
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit
compinit

# Zstyle completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion
zstyle ':completion:*' menu select # Visual selection menu
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# --- 6. History & Options ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS

# --- 7. Aliases ---
# Core
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -p'

# Modern Replacements (Mise tools)
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias ping='gping'
alias tldr='bunx tldr'
alias msync='mise run sync && exec zsh'
alias g='run_with_secrets git'
alias lg='run_with_secrets lazygit'
alias gh='run_with_secrets gh'
alias claude='run_with_secrets claude'

# --- 8. Tool Integrations & Completions ---

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
    source <(starship completions zsh)
fi

# 1Password CLI
if command -v op >/dev/null; then
    eval "$(op completion zsh)"
    compdef _op op
fi

# GitHub CLI
if command -v gh >/dev/null; then
    eval "$(gh completion -s zsh)"
fi

# UV
if command -v uv >/dev/null; then
    source <(uv generate-shell-completion zsh)
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

# --- 10. Late Load Plugins (Must be last) ---
zsh_add_plugin "https://github.com/zsh-users/zsh-autosuggestions"
zsh_add_plugin "https://github.com/zsh-users/zsh-syntax-highlighting"

# Suggestion style
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"
