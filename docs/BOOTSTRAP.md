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

## Supported Systems

| Rocky Linux | dnf | Tested |
| Oracle Linux | dnf | Tested |

## Step-by-Step

### Step 1 — Run Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

This will:
1. Detect your OS
2. Install Homebrew (macOS) or use apt/dnf (Linux)
3. Install core tools: git, curl, bash, tmux, gh, nvim
4. Install 1Password CLI
5. Clone dotfiles to `~/.dotfiles`
6. Create symlinks to your home directory

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

Now `ops` will automatically inject `GITHUB_TOKEN` from 1Password!

### Step 4 — Authenticate GitHub CLI

```bash
# Using the secret from 1Password
ops -- bash -c 'echo "$GITHUB_TOKEN" | gh auth login --with-token'
```

### Step 5 — Verify

```bash
# Reload shell
source ~/.bashrc

# Check git config
git config user.name   # Should show your name
git config user.email  # Should show your email

# Check Zellij
z --version

# Check Neovim
v --version

# Check 1Password
op vault list

# Check GitHub CLI
gh auth status
```

## Manual Installation

If you prefer to install manually:

### 1. Clone Dotfiles

```bash
git clone https://github.com/msavdert/dotfiles.git ~/.dotfiles
```

### 2. Create Symlinks

```bash
cd ~/.dotfiles
bash scripts/link.sh
```

### 3. Install Tools

```bash
# macOS
brew install git curl bash tmux gh bash-completion@2

# Ubuntu/Debian
sudo apt-get install git curl bash tmux gh bash-completion jq

# RHEL/Rocky/Oracle Linux
sudo dnf install git curl bash tmux jq
```

### 4. Install 1Password CLI

See: https://1password.com/downloads/command-line/

## 1Password Integration

### Storing Secrets

Store secrets in 1Password with these naming conventions:

| Secret | Item Name | Field |
|--------|-----------|-------|
| GitHub token | dotfiles | GITHUB_TOKEN |
| Database password | dotfiles | DB_PASSWORD |
| API key | dotfiles | API_KEY |

### Using Secrets

```bash
# Get a secret directly
ops --secret DB_PASSWORD -- echo $DB_PASSWORD

# Run a command with secrets
ops -- psql

# Export all secrets from an item
eval "$(op signin)"
op run --no-interactive -- echo "$SECRET_NAME"
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
├── tmux/
│   └── .tmux.conf    # → ~/.tmux.conf
└── ssh/
    └── config        # → ~/.ssh/config
```

## Troubleshooting

### "bash: git: command not found"

Install git manually:

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y git

# RHEL/Rocky
sudo dnf install -y git

# macOS
brew install git
```

### "bash: tmux: command not found"

```bash
# Ubuntu/Debian
sudo apt-get install -y tmux

# macOS
brew install tmux
```

### "op: command not found"

Install 1Password CLI:

```bash
# macOS
brew install 1password-cli

# Linux
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian stable main" | sudo tee /etc/apt/sources.list.d/1password.list
sudo apt-get update && sudo apt-get install -y 1password-cli
```

### Git prompt shows empty name/email

Set your git identity:

```bash
export GIT_AUTHOR_NAME="Your Name"
export GIT_AUTHOR_EMAIL="you@example.com"
```

Add to `~/.bash_profile` to persist.

### Tmux prefix not working (C-a not working)

The config uses `C-a` as prefix (instead of default `C-b`). Press `C-a` then your command.

## Next Steps

- Add your SSH keys to 1Password
- Customize aliases in `~/.bash_aliases`
- Add personal settings to `~/.bashrc`
- Configure your editor: `export EDITOR=vim`

## Uninstall

To remove the symlinks and restore backups:

```bash
cd ~/.dotfiles
./scripts/unlink.sh  # Removes symlinks, restores backups
rm -rf ~/.dotfiles    # Remove repo
```
