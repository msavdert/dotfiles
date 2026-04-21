# 🚀 Modern Dev Space (dotfiles)

A lightweight, high-performance, and **mise-native** development environment designed for cloud workspaces (Dokploy, Docker, etc.) and local development.

---

## 🚀 Quick Start
One command to rule them all:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

## ✨ Highlights

- **User-Space First**: Installs everything to `~/.local/bin`. No root/sudo required.
- **Idempotent**: Safe to run multiple times; it only installs or updates what's missing.
- **Modern Stack**: Replaces legacy tools with high-performance alternatives:
  - **Zellij**: Modern terminal multiplexer
  - **Neovim**: Hyper-extensible text editor
  - **1Password CLI**: Secure secret management
  - **uv**: Blazing fast Python & tool manager
  - **ripgrep (rg)**: Fast recursive search
  - **fd & fzf**: Fast find & fuzzy finder
  - **bat & eza**: Modern `cat` and `ls` replacements
  - **zoxide**: Smarter `cd` command
  - **starship**: Minimal, blazing-fast, and infinitely customizable prompt
  - **btop**: Interactive system monitor
  - **yazi**: Blazing fast terminal file manager
  - **yq & jq**: YAML/JSON processors
  - **Bun**: Fast JavaScript runtime & package manager
  - **dust & duf**: Modern CLI disk usage tools
- **Portable**: Consistent experience across Oracle Linux, Ubuntu, macOS, and Debian.
- **Secure**: Integrated with 1Password Service Accounts for secret management.
- **SSH Ready**: Interactive SSH host selector via `fzf` and 1Password SSH Agent integration.

---

## 🏗️ Infrastructure Setup (Dokploy/Docker)

For optimal results in cloud environments, use this `docker-compose.yml` snippet. It sets up the system-level foundations (locales, base packages) before the dotfiles take over the user-level configuration.

```yaml
services:
  workspace:
    image: ubuntu:latest
    environment:
      - TZ=${TZ:-America/New_York}
      - USER_NAME=${USER_NAME:-devuser}
      - OP_SERVICE_ACCOUNT_TOKEN=${OP_SERVICE_ACCOUNT_TOKEN:-}
      - LANG=en_US.UTF-8
      - LC_ALL=en_US.UTF-8
    volumes:
      - dev_space:/home/devuser
    entrypoint:
      - /bin/bash
      - -c
      - |
        apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl git locales sudo ttyd tzdata unzip zsh \
        && rm -rf /var/lib/apt/lists/*
        
        # System: Generate locale
        locale-gen en_US.UTF-8
        
        # System: Create user with ZSH as default
        if ! id -u devuser >/dev/null 2>&1; then
          useradd -m -s /usr/bin/zsh devuser
          echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        fi
        
        # System: Suppress Zsh first-run wizard
        touch /home/devuser/.zshrc

        # Infrastructure: Launch ttyd with ZSH
        exec sudo -E -H -u devuser ttyd -W -p 7681 -w /home/devuser /usr/bin/zsh
```

---

## 🔄 Maintenance & Sync

Keep your environment up to date with a single command:

```bash
mise run sync
```

This task automates:
1.  **Git Pull**: Fetches the latest dotfiles.
2.  **Symlink Refresh**: Updates all configuration links.
3.  **Tool Updates**: Installs any new tools defined in `mise.toml`.
4.  **Pruning**: Removes old tool versions to save space.

---

## 📄 License

MIT
