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
export GIT_AUTHOR_NAME="msavdert"
export GIT_AUTHOR_EMAIL="github@savdert.com"
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

### Create a Secret (Example):
If you haven't stored your GitHub token in 1Password yet, you can do it via CLI:
```bash
op item create --vault dotfiles --category login --title github "token[password]=ghp_your_pat_here"
```

### Fetch and Localize:
```bash
# This fetches the token from 1Password and writes it to your local config
echo "export GITHUB_TOKEN=\"$(op read 'op://dotfiles/github/token')\"" >> ~/.bash_local
source ~/.bashrc
```

### Best Practices for Secrets:
- **Separate Items:** Create a separate 1Password item for each service (e.g., one item for `github`, one for `openai`, one for `aws`). 
- **Why?** This makes your references cleaner (`op://dotfiles/github/token`), allows for better item history, and follows the principle of least privilege if you ever need to share specific secrets.

---

## 4. Verification

Verify that all tools are correctly installed and linked:

```bash
# Check binaries
z --version     # Zellij
v --version     # Neovim
jq --version    # jq
uv --version    # uv

# Check 1Password
op whoami

# Check GitHub
gh auth status
```

---

## 5. Troubleshooting

- **"Command not found"**: Ensure `~/.local/bin` is in your PATH. Run `source ~/.bashrc`.
- **"_get_comp_words_by_ref: command not found"**: This means the core completion package is missing.
  - **Ubuntu/Debian**: `sudo apt update && sudo apt install -y bash-completion`
  - **RHEL/Fedora**: `sudo dnf install -y bash-completion`
  - **macOS**: `brew install bash-completion@2`
- **"401 Unauthorized"**: Ensure your `GITHUB_TOKEN` is correct. You can re-run the hydration command in Step 3.
