# Bootstrap Guide (No-Sudo)

This is the comprehensive step-by-step guide for setting up your modernized, root-free dotfiles environment.

## 1. Quick Start

Run the bootstrap script to prepare your environment:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

This script will:
1. Detect architecture (x86_64, ARM64) and OS.
2. Install `gh` (GitHub CLI) as a binary.
3. Clone dotfiles to `~/.dotfiles`.
4. Install core binaries: `op`, `zellij`, `jq`, `nvim`.
5. Create symlinks for all configurations.
6. Generate shell completions for the installed tools.

---

## 2. Personal Configuration (`~/.bash_local`)

The project uses a **private** `~/.bash_local` file for your sensitive configuration. This file is ignored by Git.

### Step A: Set Git Identity
```bash
cat >> ~/.bash_local << 'EOF'
export GIT_AUTHOR_NAME="Your Name"
export GIT_AUTHOR_EMAIL="you@example.com"
EOF
source ~/.bashrc
```

### Step B: 1Password Service Account
1. Create a **Service Account** on [1Password.com](https://my.1password.com) scoped to your "dotfiles" vault.
2. Add the token to your local config:
```bash
echo 'export OP_SERVICE_ACCOUNT_TOKEN="ov_your_token_here"' >> ~/.bash_local
source ~/.bashrc
```

---

## 3. Hydrate Secrets (The Hybrid Method)

Instead of using `op run` for every command, we fetch secrets **once** and store them in your private `~/.bash_local`. This is fast, secure, and native.

### Fetch your GitHub Token:
```bash
# This fetches the token from 1Password and writes it to your local config
echo "export GITHUB_TOKEN=\"$(op read 'op://dotfiles/github/token')\"" >> ~/.bash_local
source ~/.bashrc
```

### Login to GitHub CLI:
```bash
# Since the token is now in your environment, gh will detect it automatically
gh auth status
```

---

## 4. Verification

Verify that all tools are correctly installed and linked:

```bash
# Check binaries
z --version     # Zellij
v --version     # Neovim
jq --version    # jq

# Check 1Password
op whoami

# Check GitHub
gh repo list
```

---

## 5. Troubleshooting

- **"Command not found"**: Ensure `~/.local/bin` is in your PATH (done automatically by `.bashrc`). Run `source ~/.bashrc`.
- **"401 Unauthorized"**: Ensure your `GITHUB_TOKEN` is correct. You can re-run the hydration command in Step 3.
- **Symlinks**: If you need to re-link files, run `bash ~/.dotfiles/scripts/link.sh`.
