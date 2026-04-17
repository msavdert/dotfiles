# Dotfiles

Minimal, modern, and **No-Sudo** dotfiles setup for macOS and Linux. No framework dependencies — just binaries and symlinks.

**Repository:** `https://github.com/msavdert/dotfiles`

## 🚀 Quick Start

One command to rule them all:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

## ✨ Highlights

- **User-Space First:** Installs everything to `~/.local/bin`. No root/sudo required.
- **Modern Stack:** Replaces legacy tools with high-performance alternatives:
  - **Zellij** (Multiplexer)
  - **Neovim** (Editor)
  - **1Password CLI** (Secrets)
- **Portable:** Same experience on Rocky Linux, Ubuntu, macOS, and minimal Docker containers.
- **Secure:** Integrated with 1Password Service Accounts for secret management.

## 📖 Documentation

To avoid confusion and redundancy, documentation is split logically:

1. **[Installation Guide (Bootstrap)](docs/BOOTSTRAP.md)**
   - Step-by-step setup instructions.
   - Managing secrets with 1Password.
   - Verifying your installation.

2. **[Development & Customization](DEVELOPMENT.md)**
   - Adding new tools or aliases.
   - Modifying symlinks.
   - Generating shell completions.

---

## Architecture Overview

```
dotfiles/
├── bootstrap.sh           # Main entry point (curled)
├── scripts/
│   ├── install-tools.sh  # No-sudo binary installer
│   └── link.sh           # Configuration symlinker
├── bash/                 # ~/.bashrc, aliases, profile
├── zellij/               # ~/.config/zellij/
├── git/                  # ~/.gitconfig
└── ssh/                  # ~/.ssh/config
```

## License
MIT — Feel free to use as a template!
