# --- Language & Locale ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- PATH Setup ---
# Ensure mise binaries and shims are always in PATH
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

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

# --- Completion Settings ---
# 1. Disable all default sources for SSH/SCP/SFTP
zstyle ':completion:*:*:(ssh|scp|sftp):*' user-hosts ''
zstyle ':completion:*:*:(ssh|scp|sftp):*' hosts ''
zstyle ':completion:*:*:(ssh|scp|sftp):*:users' ignored-patterns '*'

# 2. Extract clean host list from config files (strictly matching 'Host' keyword)
# Use 'command grep' to bypass any aliases (like rg) that might interpret -h as --help
_my_hosts=($(command grep -ihw '^Host' ~/.ssh/config ~/.ssh/config.local 2>/dev/null | awk '{print $2}' | grep -v '\*' | sort -u))

# 3. Use only our extracted hosts for Zsh native completion
zstyle ':completion:*:*:(ssh|scp|sftp):*' hosts $_my_hosts
zstyle ':completion:*:*:(ssh|scp|sftp):*' tag-order 'hosts'

# 4. Use the same clean list for fzf's fuzzy completion (ssh **)
_fzf_complete_ssh() {
  _fzf_complete --height 40% --reverse --border --prompt="🚀 SSH Host > " --preview 'dig {}' -- "$@" < <(
    printf '%s\n' "${_my_hosts[@]}"
  )
}

# --- SSH Management ---
# SSH Agent configuration
# 1. Set default socket path if not already set
: ${SSH_AUTH_SOCK:=$HOME/.ssh/ssh-agent.sock}
export SSH_AUTH_SOCK

# 2. Check if the agent is responsive
ssh-add -l >/dev/null 2>&1
if [ $? -ge 2 ]; then
    # 3. Only force restart if it's our managed socket path
    if [[ "$SSH_AUTH_SOCK" == "$HOME/.ssh/ssh-agent.sock" ]]; then
        rm -f "$SSH_AUTH_SOCK"
        eval $(ssh-agent -s -a "$SSH_AUTH_SOCK") > /dev/null
    fi
fi

# Interactive SSH host selector
# Typing 'ssh' without arguments triggers fzf with hosts from ~/.ssh/config
ssh() {
  if [ $# -eq 0 ]; then
    # Filter hosts from ~/.ssh/config (ignoring wildcards)
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
# Lazy-load GitHub API Token from 1Password to speed up shell startup
_load_gh_token() {
    if [ -z "$GH_TOKEN" ] && command -v op >/dev/null; then
        echo "🔐 Fetching GitHub token from 1Password..."
        export GH_TOKEN=$(op read "op://dotfiles/GitHub/admintoken" 2>/dev/null)
        export GITHUB_TOKEN="$GH_TOKEN"
    fi
}

# Wrap gh and git commands to load token on first use
gh() { _load_gh_token; unset -f gh; command gh "$@"; }
git() { _load_gh_token; unset -f git; command git "$@"; }

# --- Final Configurations ---

# Initialize mise (Tool & Environment Manager)
if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
  eval "$(mise completion zsh)"
fi

# 1Password CLI Completion
if command -v op >/dev/null; then
  eval "$(op completion zsh)"
  compdef _op op
fi
