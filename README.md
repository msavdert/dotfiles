# Dotfiles

Minimal, modern, and **No-Sudo** dotfiles setup for macOS and Linux. No framework dependencies — just symlinks and a bootstrap script.

**Repository:** `https://github.com/msavdert/dotfiles`

## Quick Start

Bootstrap a new machine with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

After bootstrap:

1. Set git identity:
   ```bash
   export GIT_AUTHOR_NAME="Your Name"
   export GIT_AUTHOR_EMAIL="you@example.com"
   ```

2. Sign in to 1Password:
   ```bash
   op signin
   ```

3. Authenticate GitHub CLI:
   ```bash
   gh auth login
   ```

4. Reload shell:
   ```bash
   source ~/.bashrc
   ```

## What's Included

### Shell & Multiplexer
- **bash** with minimal, high-performance configuration
- **Zellij** modern terminal workspace (replaces tmux)
- **Neovim (nvim)** modernized, high-performance editor (v, vi, vim)
- Essential aliases (git, docker, navigation)
- Built-in bash completion

### Git
- Environment-based identity (no hardcoded names/email)
- Useful aliases (`g`, `gs`, `gc`, `gl`, etc.)
- Safe defaults (rebase on pull, auto-stash on rebase)

### Tools & Secrets
- **GitHub CLI (gh)** for repository and PR management
- **1Password CLI (op)** integration via `ops` helper
- **Neovim (nvim)** modernized editor
- **jq** for JSON processing

## Project Structure

```
dotfiles/
├── bootstrap.sh           # Main bootstrap script
├── bash/
│   ├── .bashrc           # Shell configuration
│   ├── .bash_aliases     # Aliases
│   └── .bash_profile     # Login shell
├── git/
│   └── .gitconfig        # Git configuration
├── zellij/
│   └── config.kdl        # Zellij configuration
├── ssh/
│   └── config            # SSH client config
└── scripts/
    ├── link.sh           # Create symlinks
    ├── install-tools.sh  # Install tools only (no-sudo)
    └── ops.sh            # 1Password helper
```

## Common Tasks

### Add a new alias
Edit `bash/.bash_aliases`, then:
```bash
source ~/.bashrc
```

### Update dotfiles
```bash
cd ~/.dotfiles && git pull origin main
```

### Install new tools
```bash
# Re-run installation for all tools (no-sudo binary downloads)
./scripts/install-tools.sh
```

### Use 1Password secrets
```bash
# Run a command with secrets loaded
ops -- gh auth status

# Get a specific secret
ops --secret API_KEY -- echo $API_KEY
```


## Local Customization

The project supports a private configuration file at `~/.bash_local`. Use this for sensitive environment variables that should NOT be pushed to GitHub:

1. Create the file:
   ```bash
   touch ~/.bash_local
   ```
2. Add your private exports (Git identity, API tokens, etc.):
   ```bash
   export GIT_AUTHOR_NAME="Your Name"
   export GIT_AUTHOR_EMAIL="you@example.com"
   # Reference to a secret in 1Password
   export GITHUB_TOKEN="op://dotfiles/github/token"
   ```

## Security & Secrets

For maximum security, this project recommends using **1Password Service Accounts** and **Secret References**. This allows the CLI to access **only specific vaults** and inject secrets into the environment ONLY at runtime.

- **Vault Scoping:** Create a dedicated vault (e.g., "dotfiles") in 1Password.
- **Service Account:** Generate a token scoped only to that vault and save it as `OP_SERVICE_ACCOUNT_TOKEN` in `~/.bash_local`.
- **Secret References:** Use the format `op://vault/item/field` to reference secrets in your environment variables.
- **Execution:** Use the `ops -- <command>` helper to run commands with resolved secrets.

## Supported Systems

- **macOS** (Ventura and later)
- **Linux** (Ubuntu, Rocky, Oracle, etc.)
- **Architectures:** x86_64, ARM64 (Apple Silicon)
- **Debian** 11+
- **Rocky Linux / Oracle Linux** 8+

## Design Principles

1. **No-Sudo / User-Space** — Everything installs to `~/.local/bin`. No root access required.
2. **Binary Performance** — Installs optimized binaries directly from GitHub releases.
3. **No framework dependencies** — No mise, chezmoi, or oh-my-zsh. Just bash and symlinks.
4. **Works in minimal environments** — Handles absence of `git`, `unzip`, etc. gracefully.
5. **Simple prompt** — High performance PS1 with fast git status.

## License

MIT — Feel free to use as a template!
