# =============================================================================
# .zshrc - interactive shells only
# =============================================================================
# Shared by macOS (thin client) and the devbox container. Every block is guarded
# so a missing tool is a no-op rather than an error.
#
# Design rules (docs/00-architecture.md, "Shell start-up budget"):
#   1. No network calls at start-up.  Secrets are fetched per-command via `op
#      run`, never eagerly - see the "Secrets" section below.
#   2. No `source <(tool completion zsh)`.  Completions are pre-generated into
#      $ZSH_COMPLETIONS by `mise run completions:regen`, which runs at image
#      build time.  Sourcing them at start-up costs one fork per tool.
#   3. `compinit` uses its cache and only does the security scan once a day.
# =============================================================================

# --- Locale / terminal -------------------------------------------------------
# NOTE: TERM is deliberately NOT set here. The terminal emulator knows what it
# is; overriding it to xterm-256color loses undercurl, truecolor detection and
# correct keys inside zellij. If a terminal reports something the remote host
# has no terminfo entry for, fix it with `infocmp -x | ssh host tic -x -`.

# --- History -----------------------------------------------------------------
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d ${HISTFILE:h} ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY          # record timestamps
setopt SHARE_HISTORY             # sync between running shells
setopt HIST_IGNORE_ALL_DUPS      # keep only the most recent copy of a command
setopt HIST_IGNORE_SPACE         # leading space keeps it out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY               # expand !! but let me confirm before running

setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# --- Completion --------------------------------------------------------------
export ZSH_COMPLETIONS="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"
[[ -d $ZSH_COMPLETIONS ]] && fpath=("$ZSH_COMPLETIONS" $fpath)

autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d ${_zcompdump:h} ]] || mkdir -p "${_zcompdump:h}"
# Run the (slow) security scan at most once every 24h, use the cache otherwise.
# The glob qualifier must be expanded in an array assignment - inside [[ ]] zsh
# does no filename generation, so the common `[[ -n file(#qN.mh+24) ]]` idiom
# silently always takes the slow branch.
_zcompstale=( ${_zcompdump}(N.mh+24) )
if (( ${#_zcompstale} )) || [[ ! -f $_zcompdump ]]; then
    compinit -d "$_zcompdump"
    touch "$_zcompdump"
else
    compinit -C -d "$_zcompdump"
fi
unset _zcompdump _zcompstale

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"

# --- Tool integration --------------------------------------------------------
# `mise activate` replaces the shims from .zshenv with direct paths and keeps
# them in sync on every directory change.
if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
fi

(( $+commands[zoxide] ))   && eval "$(zoxide init zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# fzf ships its own keybindings (Ctrl-R history, Ctrl-T files).
(( $+commands[fzf] )) && source <(fzf --zsh)

# --- Secrets -----------------------------------------------------------------
# Secrets are NEVER exported into the shell environment. Each wrapper below
# resolves its op:// references in a single `op run` call, injects them into
# that one process, and they disappear when it exits.
#
# Why not export at start-up: N secrets meant N network round-trips on every
# new terminal, and anything in the environment leaks into every child process
# and into /proc/<pid>/environ. See docs/05-secrets.md.
#
# NOTE: this is ~/.config/op-env, NOT ~/.config/op. The latter is the 1Password
# CLI's own state directory (its config file and daemon socket live there);
# putting our files on top of it breaks `op` completely.
OP_ENV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/op-env"

if (( $+commands[op] )) && [[ -d $OP_ENV_DIR ]]; then
    # Usage: opwith ai claude   ->  op run --env-file ~/.config/op/ai.env -- claude
    opwith() {
        local env_name="$1"; shift
        local env_file="$OP_ENV_DIR/${env_name}.env"
        if [[ ! -f $env_file ]]; then
            print -u2 "opwith: no such env file: $env_file"
            return 1
        fi
        op run --no-masking --env-file="$env_file" -- "$@"
    }

    # Autocompletion for opwith: 1st arg completes env files, remaining args use standard command completion
    _opwith() {
        local -a envs
        envs=(${OP_ENV_DIR}/*.env(N:t:r))
        _arguments -C \
            "1:env file:($envs)" \
            "*::command:_normal"
    }
    compdef _opwith opwith

    # `op run` execs the binary directly (PATH lookup, no shell), so these
    # functions cannot recurse into themselves.
    claude()   { opwith ai claude "$@"; }
    kilocode() { opwith ai kilocode "$@"; }
fi

# --- Aliases -----------------------------------------------------------------
# Editors (Guarded: Fallback to system vim/vi on macOS if nvim is not installed)
if (( $+commands[nvim] )); then
    alias vim='nvim'           # Full Neovim (all plugins & config loaded)
    alias vi='nvim --clean'    # Super light Vi mode (0 plugins, instant startup)
    alias v='nvim --clean'     # Super light Vi mode shortcut
fi
alias ..='cd ..'
alias ...='cd ../..'

# Modern tools get their OWN names. Shadowing grep/find/cat with rg/fd/bat
# breaks every script and pasted command that relies on POSIX flags - and it
# silently rewrites these very functions, because zsh expands aliases inside
# function bodies at definition time.
(( $+commands[eza] )) && {
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons'
}
(( $+commands[bat] ))  && alias bcat='bat --style=plain'
(( $+commands[dust] )) && alias duh='dust'
(( $+commands[gping] )) && alias pingg='gping'

# Kubernetes
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kns='kubectl config set-context --current --namespace'
alias kctx='kubectl config use-context'
(( $+functions[__start_kubectl] )) && compdef __start_kubectl k

# --- Functions ---------------------------------------------------------------
# `command` prefixes below are load-bearing: they bypass any alias or function
# of the same name.

# ssh with no arguments -> fuzzy host picker built from the ssh config files.
ssh() {
    if (( $# > 0 )); then
        command ssh "$@"
        return
    fi
    local host
    host=$(command awk '/^[Hh]ost / { for (i=2; i<=NF; i++) if ($i !~ /[*?]/) print $i }' \
              ~/.ssh/config ~/.ssh/config.local 2>/dev/null \
           | command sort -u \
           | fzf --height 40% --reverse --border --prompt='ssh > ')
    [[ -n $host ]] && command ssh "$host"
}

# zs -> pick a directory from zoxide's frecency list, attach/create a zellij
# session named after it. This is the "resume where I left off" entry point.
zs() {
    (( $+commands[zellij] && $+commands[zoxide] && $+commands[fzf] )) || {
        print -u2 "zs: needs zellij, zoxide and fzf"; return 1
    }
    local dir
    dir=$(zoxide query -l | fzf --height 40% --reverse --border --prompt='session > ')
    [[ -n $dir ]] || return 0
    local name="${${dir:t}//[^a-zA-Z0-9_-]/_}"
    zellij attach "$name" 2>/dev/null \
        || (cd "$dir" && zellij --session "$name")
}

# --- SSH agent ---------------------------------------------------------------
# Only start an agent if nothing else already provides one. On macOS that is the
# 1Password agent (see configs/ssh/config.macos); inside the devbox it is the
# forwarded agent from the laptop. Starting our own would shadow both.
if [[ -z ${SSH_AUTH_SOCK:-} ]] && (( $+commands[ssh-agent] )); then
    _agent_sock="${XDG_RUNTIME_DIR:-$HOME/.ssh}/ssh-agent.sock"
    if [[ ! -S $_agent_sock ]]; then
        rm -f "$_agent_sock"
        eval "$(ssh-agent -s -a "$_agent_sock")" >/dev/null
    fi
    export SSH_AUTH_SOCK="$_agent_sock"
    unset _agent_sock
fi

# --- Plugins -----------------------------------------------------------------
# Order matters: zsh-syntax-highlighting wraps every widget that exists when it
# is sourced, so it must come last.
ZSH_PLUGINS="${XDG_DATA_HOME:-$HOME/.local/share}/zsh-plugins"
if [[ -d $ZSH_PLUGINS ]]; then
    source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" 2>/dev/null
    source "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" 2>/dev/null
fi

# --- Local overrides ---------------------------------------------------------
# Machine-specific, never committed.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
