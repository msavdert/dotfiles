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
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create user
ARG USERNAME=melih
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo $USERNAME ALL=\(ALL\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

USER $USERNAME
WORKDIR /home/$USERNAME

# Expose code-server port
EXPOSE 8080

# The shell will be corrected via bootstrap.sh inside the container
ENV SHELL=/bin/bash

CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password"]
