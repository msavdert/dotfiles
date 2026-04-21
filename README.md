# 🚀 Modern Dev Space (dotfiles)

A lightweight, high-performance, and **mise-native** development environment designed for cloud workspaces (Dokploy, Docker, etc.). 

This repository uses a **"Rootless Architecture"**, separating system-level infrastructure from user-level configuration.

---

## 🏗️ Architecture Philosophy

1. **Infrastructure Layer (`docker-compose.yml`)**: Handles system packages, locales, timezone, and the default shell. This layer requires root/sudo privileges and sets up the foundation.
2. **Configuration Layer (`install.sh`)**: Handles dotfiles symlinking, `mise` tool management, and personalized environment settings. This layer is strictly **user-level** and does not require `sudo`.

---

## 🛠️ Tooling Stack

- **[Mise](https://mise.jdx.dev/)**: The next-generation tool manager (replaces asdf/direnv).
- **[Starship](https://starship.rs/)**: Cross-shell lightning-fast prompt.
- **[Zsh](https://www.zsh.org/)**: The powerful interactive shell.
- **[Zellij](https://zellij.dev/)**: A modern terminal multiplexer.
- **[Neovim](https://neovim.io/)**: Modern text editor.
- **[UV](https://github.com/astral-sh/uv)**: Extremely fast Python package manager.
- **[Bun](https://bun.sh/)**: All-in-one JavaScript runtime & toolkit.
- **[Eza](https://github.com/eza-community/eza)** / **[Bat](https://github.com/sharkdp/bat)** / **[Lazygit](https://github.com/jesseduffield/lazygit)**: Modern CLI utilities.

---

## 🏁 Quick Start

### 1. Configure the Infrastructure (Dokploy/Docker)
The environment expects certain system dependencies to be present. Use this `docker-compose.yml` snippet for your Dokploy workspace for optimal results:

```yaml
services:
  workspace:
    image: ubuntu:latest
    environment:
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
        exec sudo -u devuser ttyd -W -p 7681 -w /home/devuser /usr/bin/zsh
```

### 2. Bootstrap the Configuration
Once inside your terminal (ttyd), run the following command to provision your personalized workspace:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
```

### 3. Activate the Environment
Refresh your current session to see the changes:
```bash
exec zsh
```

---

## 🔄 Maintenance & Sync

When you push new configurations to your GitHub repository, you can synchronize your workspace without re-running the full installer:

```bash
mise run sync
```
This task will:
1. `git pull` the latest changes from your repository.
2. Re-create all symbolic links via `scripts/setup-symlinks.sh`.
3. Install any new tools added to `mise.toml`.
4. **Prune** any unused tool versions (automated).

---

## 🗄️ File Structure

- `install.sh`: The rootless bootstrap script.
- `mise.toml`: Tool definitions and custom tasks (e.g., `sync`).
- `configs/`: Raw configuration files (symlinked to `~/.config/`).
- `scripts/`: Internal helper scripts for maintaining the system.
  - `setup-symlinks.sh`: Logic for creating and maintaining config links.

---

## 🔐 Security (Mise Trust)
The installer automatically handles `mise trust` for the dotfiles directory to ensure a seamless experience without security prompts every 
time you enter a folder or load a task.

---

## 📄 License
MIT
