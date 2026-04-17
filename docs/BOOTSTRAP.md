# Bootstrap Guide (No-Sudo)

Complete guide for setting up your modernized, root-free dotfiles environment on any Linux or macOS system.

## Overview

```
┌──────────────┐      ┌────────────────┐      ┌───────────┐
│ bootstrap.sh │ ───► │ ~/.local/bin   │ ───► │  Symlinks │
│  (No-Sudo)   │      │ (Binaries)     │      │  (link)   │
└──────────────┘      └────────────────┘      └───────────┘
```

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

## Step-by-Step

### Step 1 — Run Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

This will:
1. Detect your OS and Architecture (x86_64, ARM64)
2. Install GitHub CLI (`gh`) as a binary
3. Clone dotfiles to `~/.dotfiles`
4. Install core tools as binaries: `op`, `zellij`, `jq`, `nvim`
5. Create symlinks for all configurations
6. Generate shell completions for all tools

### Step 2 — Set Git Identity

Add your identity to the **private** `~/.bash_local` file so it is never pushed to public repositories:

```bash
cat >> ~/.bash_local << 'EOF'
export GIT_AUTHOR_NAME="msavdert"
export GIT_AUTHOR_EMAIL="github@savdert.com"
EOF
source ~/.bashrc
```

### Step 3 — Secure 1Password Setup (Recommended)

Instead of a full login, use a **Service Account** and **Secret References** for stable, scoped access:

1.  Log in to **1Password.com**.
2.  Create a new vault named **"dotfiles"**.
3.  Go to **Developer > Directory > Service Accounts** and create a token scoped **only** to the "dotfiles" vault.
4.  Save the token to your local config:
    ```bash
    echo 'export OP_SERVICE_ACCOUNT_TOKEN="ov_your_token"' >> ~/.bash_local
    source ~/.bashrc
    ```
5.  Create a secret item via CLI (or in the browser):
    ```bash
    # This creates an item named 'github' with a 'token' field
    op item create --vault dotfiles --category login --title github "token[password]=ghp_your_pat_here"
    ```
6.  Reference the secret in your `~/.bash_local`:
    ```bash
    echo 'export GITHUB_TOKEN="op://dotfiles/github/token"' >> ~/.bash_local
    source ~/.bashrc
    ```

Now `op run` will automatically inject `GITHUB_TOKEN` from 1Password!

### Step 4 — Authenticate GitHub CLI

```bash
# Using the secret from 1Password via native op run
op run -- bash -c 'echo "$GITHUB_TOKEN" | gh auth login --with-token'
```

### Step 5 — Verify

```bash
# Reload shell
source ~/.bashrc

# Check git config
git config user.name   # Should show your name
git config user.email  # Should show your email

# Check Tools
z --version     # Zellij
v --version     # Neovim
jq --version    # jq

# Check 1Password
op vault list

# Check GitHub CLI
gh auth status
```

## 1Password Integration

### Using Secrets

The most secure way to use secrets is via **Secret References** and the `op run` command:

```bash
# Run any command with secrets injected from 1Password
op run -- my-command

# Example: Run a script that needs an API key
op run -- ./deploy.sh
```

## Directory Structure

```
~/.dotfiles/           # Clone of this repo
├── bash/
│   ├── .bashrc       # → ~/.bashrc
│   ├── .bash_aliases # → ~/.bash_aliases
│   └── .bash_profile # → ~/.bash_profile
├── git/
│   └── .gitconfig    # → ~/.gitconfig
├── zellij/
│   └── config.kdl    # → ~/.config/zellij/config.kdl
└── ssh/
    └── config        # → ~/.ssh/config
```

## Uninstall

To remove the symlinks and restore backups:

```bash
cd ~/.dotfiles
./scripts/unlink.sh  # Removes symlinks, restores backups
rm -rf ~/.dotfiles    # Remove repo
```
