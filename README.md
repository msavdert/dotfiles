# Dotfiles

Minimal, modern, and **No-Sudo** dotfiles setup for macOS and Linux. No framework dependencies — just symlinks and a bootstrap script.

**Repository:** `https://github.com/msavdert/dotfiles`

## Quick Start

Bootstrap a new machine with one command:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

After bootstrap:

1.  **Set git identity** in `~/.bash_local`:
    ```bash
    cat >> ~/.bash_local << 'EOF'
    export GIT_AUTHOR_NAME="Your Name"
    export GIT_AUTHOR_EMAIL="you@example.com"
    EOF
    source ~/.bashrc
    ```

2.  **Authenticate 1Password** (using a Service Account):
    ```bash
    # Set your token in ~/.bash_local
    export OP_SERVICE_ACCOUNT_TOKEN="ov_your_token"
    ```

3.  **Authenticate GitHub CLI**:
    ```bash
    op run -- bash -c 'echo "$GITHUB_TOKEN" | gh auth login --with-token'
    ```

## What's Included

### Shell & Multiplexer
- **bash** with minimal, high-performance configuration
- **Zellij** modern terminal workspace (replaces tmux)
- **Neovim (nvim)** modernized editor (binaries for x86_64 and ARM64)
- **Built-in bash completion** for gh, op, and zellij

### Git
- Environment-based identity (no hardcoded names/email in config)
- Useful aliases (`g`, `gs`, `gc`, `gl`, etc.)
- Safe defaults (rebase on pull, auto-stash on rebase)

### Tools & Secrets
- **GitHub CLI (gh)** for repository and PR management
- **1Password CLI (op)** native integration for secret management
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
└── scripts/
    ├── link.sh           # Create symlinks
    └── install-tools.sh  # Install tools only (no-sudo)
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

### Use 1Password secrets (Native)

The most secure way to use secrets is via **Secret References** and the `op run` command:

```bash
# Run a command with secrets resolved from 1Password
op run -- gh auth status

# Use a specific secret in a command
op run -- bash -c 'echo "$MY_SECRET" | some-command'
```

## Local Customization

The project supports a private configuration file at `~/.bash_local`. Use this for sensitive environment variables that should NOT be pushed to GitHub:

1. Create the file:
   ```bash
   touch ~/.bash_local
   ```
2. Add your private exports:
   ```bash
   export GIT_AUTHOR_NAME="Your Name"
   export GIT_AUTHOR_EMAIL="you@example.com"
   # Reference a secret in 1Password
   export MY_SECRET="op://vault/item/field"
   ```

## Security & Secrets

For maximum security, this project recommends using **1Password Service Accounts** and **Secret References**.

- **Vault Scoping:** Create a dedicated vault (e.g., "dotfiles") in 1Password.
- **Service Account:** Generate a token scoped only to that vault and save it as `OP_SERVICE_ACCOUNT_TOKEN` in `~/.bash_local`.
- **Secret References:** Use the format `op://vault/item/field` to reference secrets in your environment variables.
- **Execution:** `op run -- <command>` will automatically inject your secrets!

## Supported Systems

- **macOS** (Ventura and later)
- **Linux** (Ubuntu, Rocky, Oracle, Debian, etc.)
- **Architectures:** x86_64 (amd64), ARM64 (Apple Silicon, ARM Servers)

## License

MIT — Feel free to use as a template!
