# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **minimal, modern, and No-Sudo dotfiles repository** for macOS and Linux. It focuses on user-space binary management and high-performance bash configuration.

## Architecture

### Tool Stack
- **User-space Binaries** — Everything installed to `~/.local/bin` (No root/sudo required).
- **GitHub CLI** (`gh`) — Primary repo and project management tool.
- **1Password CLI** (`op`) — Secrets management.
- **Zellij** — Modern terminal workspace (multiplexer).
- **bash** — High-performance shell with fast git prompt.

### Structure
```
dotfiles/
├── bootstrap.sh       # Main bootstrap script (No-Sudo)
├── bash/              # Shell configs (.bashrc, .bash_aliases, .bash_profile)
├── git/               # Git config (.gitconfig)
├── zellij/            # Zellij config (config.kdl)
├── ssh/               # SSH config (config)
└── scripts/           # Helper scripts
    ├── link.sh        # Create symlinks to home directory
    ├── install-tools.sh # Install tools as binaries (no-sudo)
    └── ops.sh         # 1Password CLI helper
```

### Symlink Model
All configs are symlinked from `~/.dotfiles/` to `~`. For example:
- `~/.dotfiles/bash/.bashrc` → `~/.bashrc`
- `~/.dotfiles/zellij/config.kdl` → `~/.config/zellij/config.kdl`

## Common Commands

### Bootstrap (fresh machine)
```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

### Update dotfiles
```bash
cd ~/.dotfiles && git pull origin main
./scripts/link.sh  # Re-create symlinks if needed
```

### Install tools manually
```bash
./scripts/install-tools.sh
```

### Use 1Password secrets
```bash
ops -- gh auth status
ops --secret API_KEY -- echo $API_KEY
```

## Git Identity

Git config uses environment variables for user identity:
- `GIT_AUTHOR_NAME` — Your name
- `GIT_AUTHOR_EMAIL` — Your email

Set in `~/.bash_profile` or `~/.bashrc`:
```bash
export GIT_AUTHOR_NAME="Your Name"
export GIT_AUTHOR_EMAIL="you@example.com"
```

## Supported Systems
- macOS (Homebrew or Binary)
- Linux (Ubuntu/Debian/Rocky/Oracle) — Optimized for minimal No-Sudo environments.

## Key Files
- `bootstrap.sh` — Robust script with smart GitHub CLI pre-install and zip extraction fallbacks.
- `bash/.bashrc` — Optimized prompt (PS1) with fast `git rev-parse` logic.
- `bash/.bash_aliases` — Essential aliases (git: `g`, `gs`, `gc`; docker: `d`, `dc`; zellij: `z`).
- `zellij/config.kdl` — Clean Zellij configuration with pane frames disabled and compact layout.

## 1Password Helper (ops.sh)
The `ops` alias runs commands with 1Password secrets injected. It checks `op whoami` to skip redundant sign-ins.
```bash
ops -- gh auth status        # Run with secrets loaded
ops --secret API_KEY -- echo $API_KEY  # Get specific secret
```

## Testing
Test on fresh VM using OrbStack or Docker:
```bash
docker run -it --rm ubuntu:24.04 bash
apt update && apt install -y curl tar python3  # Minimal dependencies
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
source ~/.bashrc
```