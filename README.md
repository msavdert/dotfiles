# Dotfiles

<p align="left">
  <img src="https://github.com/msavdert/dotfiles/actions/workflows/test.yml/badge.svg" alt="Test Status" />
  <img src="https://img.shields.io/github/license/msavdert/dotfiles?style=flat-square&color=blue" alt="License" />
  <img src="https://img.shields.io/badge/shell-bash-4E9A06?style=flat-square&logo=gnu-bash&logoColor=white" alt="Shell" />
  <img src="https://img.shields.io/badge/secrets-1password-00aeec?style=flat-square&logo=1password&logoColor=white" alt="1Password" />
  <img src="https://img.shields.io/badge/feature-idempotent-brightgreen?style=flat-square" alt="Idempotent" />
</p>

Minimal, modern, and **No-Sudo** dotfiles setup for macOS and Linux. No framework dependencies — just binaries and symlinks.

## 🚀 Quick Start

One command to rule them all:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

## ✨ Highlights

- **User-Space First:** Installs everything to `~/.local/bin`. No root/sudo required.
- **Idempotent:** Safe to run multiple times; it only installs or updates what's missing.
- **Modern Stack:** Replaces legacy tools with high-performance alternatives:
  - **Zellij** (Multiplexer)
  - **Neovim** (Editor)
  - **1Password CLI** (Secrets)
  - **uv** (Python & Tooling Manager)
  - **ripgrep (rg)** (Fast Search)
  - **fd & fzf** (Fast Find & Fuzzy Finder)
  - **bat & eza** (Modern cat & ls)
  - **zoxide** (Smarter cd)
  - **starship** (Cross-shell Prompt)
  - **btop** (System monitor)
  - **yazi** (Blazing Fast File Manager)
  - **yq & jq** (YAML/JSON Processors)
  - **Bun** (Fast JavaScript Runtime & Package Manager)
  - **dust, httpie** (Modern CLI Utils)
- **Portable:** Same experience on Oracle Linux, Ubuntu, macOS, and Debian.
- **Secure:** Integrated with 1Password Service Accounts for secret management.

## 📖 Documentation

1. **[Installation Guide (Bootstrap)](docs/BOOTSTRAP.md)** - Setup and secrets hydration.
2. **[Development & Customization](DEVELOPMENT.md)** - Adding tools, aliases, and completions.

---

## Architecture Overview

```
dotfiles/
├── bootstrap.sh           # Main entry point (installs uv & python first)
├── scripts/
│   ├── install-tools.sh  # No-sudo binary installer (gh, nvim, rg, fzf, etc.)
│   ├── link.sh           # Configuration symlinker
│   └── test-in-docker.sh # Local testing automation
├── bash/                 # ~/.bashrc, aliases, profile
├── config/               # ~/.config/ (starship, bat, btop, lazygit)
├── zellij/               # ~/.config/zellij/
├── git/                  # ~/.gitconfig
├── ssh/                  # ~/.ssh/config
└── nvim/                 # ~/.config/nvim/
```

## License
MIT — Feel free to use as a template!
