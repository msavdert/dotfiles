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
alias tldr='bunx tldr'
alias msync='mise run sync && exec zsh'
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

# --- Completion & Style ---
# Add completions to fpath
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit
compinit

# Zstyle completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion
zstyle ':completion:*' menu select # Visual selection menu
zstyle ':completion:*:descriptions' format '[%d]'

# --- Tools Integration ---

# Mise
if command -v mise >/dev/null; then
    eval "$(mise activate zsh)"
fi

# Zoxide
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Starship
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
    source <(starship completions zsh)
fi

# UV
if command -v uv >/dev/null; then
    source <(uv generate-shell-completion zsh)
fi

# --- FZF "Ultimate" Experience (Josean Style) ---
# https://www.josean.com/posts/7-amazing-cli-tools
if command -v fzf >/dev/null; then
    source <(fzf --zsh)

    # Use fd instead of find
    export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

    # Preview logic
    # If dir: show eza tree; if file: show bat
    show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

    export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
    export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

    # Advanced completion integration
    _fzf_comprun() {
      local command=$1
      shift
      case "$command" in
        cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
        export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
        ssh)          fzf --preview 'dig {}'                   "$@" ;;
        *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
      esac
    }

    _fzf_compgen_path() {
      fd --hidden --exclude .git . "$1"
    }

    _fzf_compgen_dir() {
      fd --type=d --hidden --exclude .git . "$1"
    }
fi

# --- Navigation & Keybindings ---
# History Search
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey -e

# --- SSH Management ---
# 1Password SSH Agent integration (macOS)
if [ -S "$HOME/Library/Group Containers/2BU85C4SDR.com.1password/t/agent.sock" ]; then
    export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BU85C4SDR.com.1password/t/agent.sock"
fi

# Fuzzy SSH host selector
# Typing 'ssh' without arguments will open fzf with hosts from ~/.ssh/config
ssh() {
  if [ $# -eq 0 ]; then
    # Get hosts from ~/.ssh/config (ignoring wildcards)
    local host=$(grep -iE "^host " ~/.ssh/config 2>/dev/null | awk '{print $2}' | grep -v '*' | fzf --height 40% --reverse --border --prompt="🚀 SSH Host > " --preview 'dig {}')
    if [ -n "$host" ]; then
      echo "Connecting to $host..."
      command ssh "$host"
    fi
  else
    command ssh "$@"
  fi
}

# --- GitHub Integration ---
# Load GitHub API Token from 1Password
if command -v op >/dev/null; then
    export GH_TOKEN=$(op read "op://dotfiles/GitHub/admintoken" 2>/dev/null)
    export GITHUB_TOKEN="$GH_TOKEN"
fi

