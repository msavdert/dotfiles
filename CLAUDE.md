# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

- **Bootstrap a fresh machine:** `curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash`
- **Sync everything (pull, symlinks, tools, prune):** `mise run sync`
- **Refresh symlinks only:** `./scripts/setup-symlinks.sh`
- **Install/update tools:** `mise install`
- **Prune old tool versions:** `mise prune --yes`
- **Pull secrets from 1Password:** `mise run secrets:pull`
- **Update Neovim plugins:** Inside nvim, run `:Lazy sync`

## Architecture

### mise-Native Tool Management
`mise.toml` is the single source of truth for all user-space tools (neovim, zellij, uv, fzf, starship, etc.). It is symlinked to `~/.config/mise/config.toml` by `setup-symlinks.sh`. The `[tasks.sync]` task is the primary maintenance workflow: it hard-resets the repo from `origin/main`, refreshes symlinks, installs tools, and prunes unused versions.

### Bootstrap & Symlinks
- `bootstrap.sh` is designed to be piped from GitHub. It clones the repo, installs mise, runs `setup-symlinks.sh`, and installs tools.
- `scripts/setup-symlinks.sh` is idempotent and creates timestamped backups (e.g., `.20250101120000.bak`) before overwriting any existing file or directory.
- Symlinked targets include: `~/.zshrc`, `~/.gitconfig`, `~/.config/starship.toml`, `~/.config/nvim`, `~/.config/zellij`, `~/.ssh/config`, and `~/.config/mise/config.toml`.

### Neovim Configuration
The config is built on LazyVim. The entrypoint is `configs/nvim/init.lua` which requires `config.lazy`. Custom plugins and overrides live in `configs/nvim/lua/plugins/` and `configs/nvim/lua/config/`. The `lazyvim.json` file tracks enabled LazyVim extras (e.g., copilot). Do not manually edit `lazy-lock.json`.

### Secret Management
1Password CLI (`op`) is required for secret management. The `secrets:pull` task fetches `~/.ssh/config.local` and an SSH private key from 1Password vault items. The `OP_SERVICE_ACCOUNT_TOKEN` environment variable must be set for non-interactive use. The `~/.zshrc` lazy-loads the GitHub token on first invocation of `gh` or `git`.

### SSH Integration
The `~/.zshrc` configures an auto-starting SSH agent on a fixed socket (`~/.ssh/ssh-agent.sock`) and provides an interactive `ssh()` wrapper that launches an `fzf` host selector when called without arguments. SSH hosts for completion are extracted from `~/.ssh/config` and `~/.ssh/config.local`.

### Zellij & Starship
- Zellij config (`configs/zellij/config.kdl`) uses the `catppuccin-mocha` theme with `simplified_ui true` and `default_layout "compact"`.
- Starship config (`configs/starship.toml`) is a standalone TOML file symlinked to `~/.config/starship.toml`.
