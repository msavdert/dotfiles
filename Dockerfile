# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Build-time arguments
ARG DEV_USER=savdert
ARG DEV_UID=1000
ARG DEV_GID=1000
ARG TZ=Europe/Istanbul

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/usr/bin/zsh \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PATH="/home/${DEV_USER}/.local/bin:/opt/mise/bin:/opt/mise/shims:${PATH}"

# Install core system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    sudo \
    zsh \
    ttyd \
    ca-certificates \
    locales \
    tzdata \
    unzip \
    build-essential \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Setup locale and timezone
RUN locale-gen en_US.UTF-8 && \
    ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# Create the user with sudo privileges
RUN groupadd -g ${DEV_GID} ${DEV_USER} && \
    useradd -m -u ${DEV_UID} -g ${DEV_GID} -s /usr/bin/zsh ${DEV_USER} && \
    echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install mise globally
RUN curl https://mise.run | sh && \
    mv /root/.local/bin/mise /usr/local/bin/mise

# Setup project directory
WORKDIR /workspace
COPY . /workspace
RUN chown -R ${DEV_USER}:${DEV_USER} /workspace /home/${DEV_USER}

USER ${DEV_USER}

# Install tools via mise during the build (caching tools in the image)
RUN mise trust --quiet && \
    mise install --yes

# Symlink configurations to the user's home directory
RUN mkdir -p ${HOME}/.config/zellij ${HOME}/.config/nvim && \
    ln -sf /workspace/configs/.zshrc ${HOME}/.zshrc && \
    ln -sf /workspace/configs/starship.toml ${HOME}/.config/starship.toml && \
    ln -sf /workspace/configs/zellij/config.kdl ${HOME}/.config/zellij/config.kdl

# Expose the ttyd port
EXPOSE 7681

# Command to launch ttyd with zsh
ENTRYPOINT ["ttyd", "-W", "-p", "7681", "/usr/bin/zsh"]
