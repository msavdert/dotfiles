# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **minimal dotfiles repository** for macOS and Linux. No framework dependencies — just git and symlinks.

## Architecture

### Tool Stack
- **Homebrew** (macOS) or **apt/dnf** (Linux) for tool management
- **1Password CLI** (`op`) for secrets
- **tmux** for terminal multiplexing
- **bash** as the shell

### Structure
```
dotfiles/
├── bootstrap.sh       # Main bootstrap script
├── bash/              # Shell configs (.bashrc, .bash_aliases, .bash_profile)
├── git/               # Git config (.gitconfig)
├── tmux/              # Tmux config (.tmux.conf)
├── ssh/               # SSH config (config)
└── scripts/           # Helper scripts
    ├── link.sh        # Create symlinks to home directory
    ├── install-tools.sh # Install tools (no dotfiles clone)
    └── ops.sh         # 1Password CLI helper
```

### Symlink Model
All configs are symlinked from `~/.dotfiles/` to `~`. For example:
- `~/.dotfiles/bash/.bashrc` → `~/.bashrc`
- `~/.dotfiles/git/.gitconfig` → `~/.gitconfig`

## Common Commands

### Bootstrap (fresh machine)
```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

### Update dotfiles
```bash
cd ~/.dotfiles && git pull origin main
bash scripts/link.sh  # Re-create symlinks if needed
```

### Install tools only (no dotfiles clone)
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

Set in `~/.bash_profile`:
```bash
export GIT_AUTHOR_NAME="Your Name"
export GIT_AUTHOR_EMAIL="you@example.com"
```

## Supported OS

- macOS (Homebrew)
- Ubuntu/Debian (apt)
- Rocky Linux/Oracle Linux (dnf)

## Key Files

- `bootstrap.sh` — Single script for fresh setup
- `bash/.bashrc` — Shell config with simplified PS1 prompt (git branch shown)
- `bash/.bash_aliases` — Essential aliases (git: `g`, `gs`, `gc`; docker: `d`, `dc`; tmux: `t`, `ta`, `tk`)
- `git/.gitconfig` — Uses env vars for identity, safe defaults
- `tmux/.tmux.conf` — Prefix `C-a`, vim-style navigation, dark status bar

## Testing

Test on fresh VM using OrbStack:
```bash
orb create ubuntu test-vm
orb shell test-vm
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
source ~/.bashrc
```