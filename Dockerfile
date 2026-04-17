# Resmi ve her mimari için optimize edilmiş imajı temel alalım
FROM codercom/code-server:latest

USER root

# dotfiles için gerekli sistem paketleri
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

# Dil ayarları
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Mevcut 'coder' kullanıcısına sudo yetkisi ver (Şifresiz)
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/coder \
    && chmod 0440 /etc/sudoers.d/coder

USER coder
WORKDIR /home/coder

# Ortam değişkenleri
ENV SHELL=/bin/bash
ENV TZ=America/New_York
ENV DEFAULT_WORKSPACE=/home/coder/project

# Port zaten resmi imajda expose edilmiş durumda
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password", "/home/coder/project"]
