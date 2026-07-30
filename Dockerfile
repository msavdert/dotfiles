# =============================================================================
# devbox - the actual development environment
# =============================================================================
# Everything is installed at BUILD time. A running container never downloads a
# toolchain, never clones this repo and never runs a bootstrap script, which is
# why `docker compose up` reaches a usable shell in seconds instead of minutes.
#
# Build locally:   docker build -t devbox .
# Multi-arch:      see .github/workflows/build.yml
# Full rationale:  docs/02-devbox-image.md
# =============================================================================

FROM ubuntu:24.04

# --- System layer ------------------------------------------------------------
# Rarely changes, so it stays at the top and stays cached.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        less \
        locales \
        openssh-client \
        sudo \
        tzdata \
        unzip \
        zsh \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8

# --- User --------------------------------------------------------------------
# ubuntu:24.04 ships a stock `ubuntu` account already sitting on uid 1000.
# Remove it so `dev` gets 1000 and bind-mounted files from the host line up.
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd -g "$GID" "$USERNAME" \
    && useradd -m -u "$UID" -g "$GID" -s /usr/bin/zsh "$USERNAME" \
    && printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$USERNAME" > /etc/sudoers.d/"$USERNAME" \
    && chmod 0440 /etc/sudoers.d/"$USERNAME"

USER $USERNAME
WORKDIR /home/$USERNAME
ENV HOME=/home/$USERNAME \
    SHELL=/usr/bin/zsh \
    XDG_CONFIG_HOME=/home/$USERNAME/.config \
    XDG_DATA_HOME=/home/$USERNAME/.local/share \
    XDG_STATE_HOME=/home/$USERNAME/.local/state \
    XDG_CACHE_HOME=/home/$USERNAME/.cache

# --- mise --------------------------------------------------------------------
RUN curl -fsSL https://mise.run | MISE_QUIET=1 sh
ENV PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

# --- Toolchain ---------------------------------------------------------------
# Its own layer: this is the expensive step (several hundred MB of downloads),
# and it must only re-run when the manifest actually changes.
COPY --chown=$UID:$GID configs/mise/devbox.toml .config/mise/config.toml

# Two phases on purpose. The npm:/http: backends shell out to node, bun and
# java, so those runtimes have to exist before mise tries to resolve them.
RUN mise install -y node bun python go java rust \
    && mise install -y \
    && mise reshim \
    && mise cache clear \
    && rm -rf "$HOME/.cache/mise"

# --- Shell -------------------------------------------------------------------
COPY --chown=$UID:$GID configs/zsh/.zshenv  .zshenv
COPY --chown=$UID:$GID configs/zsh/.zshrc   .zshrc
COPY --chown=$UID:$GID configs/zsh/regen-completions.zsh .config/zsh/regen-completions.zsh
COPY --chown=$UID:$GID configs/git/config   .gitconfig
COPY --chown=$UID:$GID configs/ssh/config   .ssh/config
COPY --chown=$UID:$GID configs/op-env/      .config/op-env/
COPY --chown=$UID:$GID configs/starship.toml .config/starship.toml
COPY --chown=$UID:$GID configs/zellij/      .config/zellij/
COPY --chown=$UID:$GID configs/nvim/        .config/nvim/

RUN chmod 700 "$HOME/.ssh" && chmod 600 "$HOME/.ssh/config"

# zsh plugins are vendored into the image rather than cloned on first login.
ARG ZSH_AUTOSUGGESTIONS_REF=v0.7.1
ARG ZSH_SYNTAX_HIGHLIGHTING_REF=0.8.0
RUN mkdir -p "$HOME/.local/share/zsh-plugins" \
    && git clone --depth 1 --branch "$ZSH_AUTOSUGGESTIONS_REF" \
        https://github.com/zsh-users/zsh-autosuggestions.git \
        "$HOME/.local/share/zsh-plugins/zsh-autosuggestions" \
    && git clone --depth 1 --branch "$ZSH_SYNTAX_HIGHLIGHTING_REF" \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$HOME/.local/share/zsh-plugins/zsh-syntax-highlighting" \
    && rm -rf "$HOME/.local/share/zsh-plugins"/*/.git

# Completions are generated once here instead of on every shell start.
RUN zsh "$HOME/.config/zsh/regen-completions.zsh"

# --- Neovim plugins ----------------------------------------------------------
# Baked in so the first `nvim` is instant and offline-capable. lazy-lock.json is
# committed, so this resolves to exactly the versions recorded in the repo.
RUN nvim --headless "+Lazy! restore" +qa 2>/dev/null \
    || nvim --headless "+Lazy! sync" +qa 2>/dev/null \
    || true

# --- Runtime -----------------------------------------------------------------
# Directories that get a persistent volume mounted over them in compose.yaml.
RUN mkdir -p "$HOME/work" "$HOME/.local/state/zsh"

# The container's job is to stay alive; you enter it with `docker exec` (see
# the `Host dev` block in docs/03-vps-deployment.md). Running zellij as PID 1
# would tie the whole container's lifetime to one terminal session.
CMD ["sleep", "infinity"]
