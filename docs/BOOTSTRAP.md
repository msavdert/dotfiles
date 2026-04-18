# Bootstrap Guide (No-Sudo)

This is the comprehensive step-by-step guide for setting up your modernized, root-free dotfiles environment.

## 1. Quick Start

Run the bootstrap script to prepare your environment:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/bootstrap.sh | bash
```

This script will:
1. Detect architecture (x86_64, ARM64) and OS.
2. Install `uv` (Tool Manager) and ensure a portable Python environment.
3. Install `gh` (GitHub CLI) as a binary.
4. Clone dotfiles to `~/.dotfiles`.
5. Install core binaries: `op`, `zellij`, `jq`, `nvim`, `rg`, `fd`, `bat`, `eza`, `fzf`, `zoxide`, `delta`, `starship`, `btop`, `yazi`, `dust`, `httpie`, `bun`.
6. Create symlinks for all configurations (including the new `config/` directory).
7. Generate shell completions for the installed tools.

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

### SSH Configuration (Optional):
```bash
# Fetch SSH local config and OCI private key from 1Password
op read "op://dotfiles/texts/ssh_config.local" > ~/.ssh/config.local
chmod 600 ~/.ssh/config.local

op read "op://dotfiles/oci_key/private key" > ~/.ssh/oci_key
chmod 600 ~/.ssh/oci_key
```

---

## 4. Verification

Verify that all tools are correctly installed and linked:

```bash
# Check binaries
z --version       # Zellij
v --version       # Neovim
rg --version      # ripgrep
y --version       # yazi
btop --version    # btop
bun --version     # bun
uv --version      # uv
python --version  # uv-managed python

# Check 1Password & GitHub
op whoami
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

---

## 6. Maintenance & Updates

### Updating Tools
Since tools are installed as standalone binaries in `~/.local/bin`, the simplest and most reliable way to update a tool is to delete its binary and re-run the installation script:

```bash
# Example: Updating btop
rm ~/.local/bin/btop
./scripts/install-tools.sh
```

This forces the script to fetch the latest release from GitHub and re-install any related assets (like shell completions).

### Updating Dotfiles
To pull the latest changes from your repository and update symlinks:

```bash
cd ~/.dotfiles
git pull
./scripts/link.sh
```
