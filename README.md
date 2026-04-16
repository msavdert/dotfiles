# Dotfiles

Minimal dotfiles setup for macOS and Linux. No framework dependencies — just symlinks and a bootstrap script.

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

### Shell
- **bash** with minimal configuration
- **tmux** terminal multiplexer
- Essential aliases (git, docker, navigation)
- Built-in bash completion

### Git
- Environment-based identity (no hardcoded names/email)
- Useful aliases (`g`, `gs`, `gc`, `gl`, etc.)
- Safe defaults (rebase on pull, auto-stash on rebase)

### Secrets
- **1Password CLI** integration via `ops` helper

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
├── tmux/
│   └── .tmux.conf        # Tmux configuration
├── ssh/
│   └── config            # SSH client config
└── scripts/
    ├── link.sh           # Create symlinks
    ├── install-tools.sh  # Install tools only
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
# Install on current OS
./scripts/install-tools.sh

# Or manually with Homebrew (macOS)
brew install curl git tmux

# Or apt (Debian/Ubuntu)
sudo apt-get install git curl tmux
```

### Use 1Password secrets
```bash
# Run a command with secrets loaded
ops -- gh auth status

# Get a specific secret
ops --secret API_KEY -- echo $API_KEY
```

## Supported Systems

- **macOS** (Ventura and later)
- **Ubuntu** 20.04+
- **Debian** 11+
- **Rocky Linux** 8+
- **Oracle Linux** 8+

## Design Principles

1. **No framework dependencies** — No mise, chezmoi, or fnox. Just git and symlinks.
2. **Works in a fresh VM** — Uses system package managers, not custom tooling.
3. **Bash completion works out of the box** — Uses system bash-completion.
4. **Simple prompt** — No starship or other prompt tools. Just PS1.
5. **Git identity via environment** — `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL`.

## Migrating from Old Setup

If you're switching from the old (chezmoi/mise/fnox) setup:

1. Your `~/.bashrc`, `~/.gitconfig`, etc. will be backed up as `~/.bashrc.backup.*`
2. New symlinks will be created pointing to `~/.dotfiles/`
3. Set your git identity and 1Password secrets in your shell profile

## License

MIT — Feel free to use as a template!
