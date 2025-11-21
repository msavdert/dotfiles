FROM ubuntu:24.04

LABEL maintainer="msavdert"
LABEL description="Test environment for dotfiles - https://github.com/msavdert/dotfiles"
LABEL version="1.0"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

USER root

# Install essential packages and dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        sudo \
        curl \
        wget \
        git \
        ca-certificates \
        build-essential \
        bash-completion \
        tree \
        less \
        tzdata \
        unzip \
        fontconfig \
        locales \
        gnupg2 \
        apt-utils \
        lsb-release && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Set locale (en_US.UTF-8 for better compatibility)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create user 'msavdert' with sudo privileges
RUN useradd -ms /bin/bash msavdert && \
    echo "msavdert ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/msavdert && \
    chmod 0440 /etc/sudoers.d/msavdert

# Switch to msavdert user
USER msavdert
WORKDIR /home/msavdert

# Set bash as default shell
ENV SHELL=/bin/bash

# Set environment variables for dotfiles installation
ENV DOTFILES_REPO=https://github.com/msavdert/dotfiles.git

CMD ["/bin/bash"]
