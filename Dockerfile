# Use the official and architecture-optimized image as base
FROM codercom/code-server:latest

USER root

# System dependencies for dotfiles
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

# Locale settings
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Grant passwordless sudo access to the existing 'coder' user
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder

# Pre-create the project directory and set ownership to prevent root-owned volume mounts
RUN mkdir -p /home/coder/project && chown -R coder:coder /home/coder

USER coder
WORKDIR /home/coder

# Environment variables
ENV SHELL=/bin/bash
ENV TZ=America/New_York
ENV DEFAULT_WORKSPACE=/home/coder/project

# Port is already exposed in the base image
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password", "/home/coder/project"]
