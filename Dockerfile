FROM ubuntu:24.04

LABEL org.opencontainers.image.source=https://github.com/msavdert/dotfiles
LABEL org.opencontainers.image.description="Modern Dev Environment with Code-Server and Dotfiles"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    sudo \
    bash-completion \
    tar \
    python3 \
    locales \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create user (Handle conflict with default 'ubuntu' user in Ubuntu 24.04)
ARG USERNAME=coder
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if id -u ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo $USERNAME ALL=\(ALL\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

USER $USERNAME
WORKDIR /home/$USERNAME

# Expose code-server port
EXPOSE 8080

# Environment variables
ENV SHELL=/bin/bash
ENV TZ=UTC
ENV DEFAULT_WORKSPACE=/home/coder/project

CMD ["sh", "-c", "code-server --bind-addr 0.0.0.0:8080 --auth password ${DEFAULT_WORKSPACE}"]
