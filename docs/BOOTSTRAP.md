# Bootstrap Guide — Setting Up Your Environment from Scratch

Complete walkthrough for setting up the dotfiles environment on a fresh system. Follow these steps in order.

## Overview

```
┌──────────┐     ┌───────┐     ┌─────────┐     ┌──────┐     ┌───────────┐
│ install.sh│ ──► │ mise  │ ──► │ chezmoi │ ──► │ fnox │ ──► │ Ready! ✓  │
│ (bootstrap)│    │ (tools)│    │ (dotfiles)│   │(secrets)│   │           │
└──────────┘     └───────┘     └─────────┘     └──────┘     └───────────┘
```

---

## Method 1: OrbStack VM (Recommended for Full Testing)

### Step 1 — Create the VM

```bash
# From Mac terminal
orb create ubuntu devenv
orb -m devenv
```

### Step 2 — Run Bootstrap

```bash
# Inside the VM (git & curl are auto-installed if missing)
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
```

### Step 3 — Activate Shell

```bash
source ~/.bashrc
```

### Step 4 — Verify Installation

```bash
# All tools installed?
mise list

# Chezmoi healthy?
chezmoi doctor

# Git config templated correctly?
git config user.name     # Should show: msavdert
git config user.email    # Should show: 10913156+msavdert@users.noreply.github.com

# Prompt working?
starship --version

# Aliases loaded?
alias | wc -l            # Should be 100+
```

> **Note:** `chezmoi doctor` may show a hardlink error on OrbStack/Docker — this is expected (cross-device link) and doesn't affect functionality.

### Step 5 — Set Up fnox Secrets

See [fnox Setup](#fnox-setup-secrets) below.

### Cleanup

```bash
# Exit VM
exit

# Delete VM when done testing
orb delete devenv
```

---

## Method 2: Docker Container

### Step 1 — Build & Enter

```bash
cd ~/Documents/all/github/dotfiles
make build
make shell
```

### Step 2 — Run Bootstrap Inside Container

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
source ~/.bashrc
```

### Step 3 — Verify

Same verification commands as Method 1.

### Cleanup

```bash
exit
make clean    # Stop container and remove volumes
```

---

## Method 3: Fresh Linux Machine (Real Server/Desktop)

### Step 1 — Ensure Required Packages

```bash
# On Ubuntu/Debian (install.sh does this automatically now)
sudo apt update && sudo apt install -y curl git

# On RHEL/Fedora
sudo dnf install -y curl git
```

### Step 2 — Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
source ~/.bashrc
```

### Step 3 — Verify + fnox Setup

Same steps as above, then proceed to fnox setup.

---

## fnox Setup (Secrets)

fnox uses age encryption to manage secrets. After bootstrap, you need to either **restore your existing key** or **create a new one**.

### Option A: Restore Existing Key (Existing User)

If you already have an age key backed up (password manager, USB, etc.):

```bash
# 1. Create fnox config directory
mkdir -p ~/.config/fnox && chmod 700 ~/.config/fnox

# 2. Restore the private key from your backup
#    Option 2a: From password manager — paste the key content:
cat > ~/.config/fnox/key.txt << 'EOF'
# created: 2024-xx-xx
# public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
EOF

#    Option 2b: From USB:
cp /mnt/usb/fnox-key.txt ~/.config/fnox/key.txt

# 3. Set strict permissions
chmod 600 ~/.config/fnox/key.txt

# 4. Verify — should list all your secrets
fnox list
fnox get GITHUB_TOKEN_GENERAL    # Should decrypt successfully
```

### Option B: First-Time Setup (New User)

If this is your very first time setting up fnox:

```bash
# 1. Generate a new age keypair
mkdir -p ~/.config/fnox && chmod 700 ~/.config/fnox
age-keygen -o ~/.config/fnox/key.txt
chmod 600 ~/.config/fnox/key.txt

# Output will show your PUBLIC key:
# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
# SAVE THIS PUBLIC KEY — you need it for fnox.toml

# 2. Initialize fnox
fnox init --provider age --recipient "age1ql3z..."

# 3. Add your first secret
fnox set GITHUB_TOKEN_GENERAL "ghp_xxxxxxxxxxxxxxxxxxxx"

# 4. Verify
fnox list
fnox get GITHUB_TOKEN_GENERAL

# 5. CRITICAL — Backup your key!
cat ~/.config/fnox/key.txt
# → Copy the entire content to a secure note in your password manager

# 6. Commit the updated fnox.toml to git
cd ~/.local/share/chezmoi
cp ~/.config/fnox/fnox.toml ./fnox.toml
git add fnox.toml && git commit -m "add fnox secrets" && git push
```

> **⚠️ WARNING:** Lost key = lost secrets permanently. Always back up `key.txt` in multiple locations.

---

## fnox Best Practices & Examples

### Best Practice: Organize with Profiles

Separate secrets by context using profiles:

```bash
# Default profile — personal/general secrets
fnox set GITHUB_TOKEN_GENERAL "ghp_personal_token"
fnox set CLOUDFLARE_API_TOKEN "cf_api_token"

# Work profile — work-related secrets
fnox set --profile work DB_HOST "prod-db.company.com"
fnox set --profile work DB_USER "admin"
fnox set --profile work DB_PASSWORD "super-secret"

# OCI profile — cloud credentials
fnox set --profile oci_aysesmenn OCI_TENANCY_OCID "ocid1.tenancy..."
fnox set --profile oci_aysesmenn OCI_USER_OCID "ocid1.user..."
fnox set --profile oci_aysesmenn OCI_REGION "eu-frankfurt-1"
```

### Example 1: GitHub CLI Authentication

```bash
# Store token
fnox set GITHUB_TOKEN_GENERAL "ghp_xxxxxxxxxxxxxxxxxxxx"

# Authenticate GitHub CLI using fnox
fnox exec -- bash -c 'echo $GITHUB_TOKEN_GENERAL | gh auth login --with-token'
gh auth setup-git

# Or use the mise task shortcut:
mise run ghl-gen
```

### Example 2: PostgreSQL Connection

```bash
# Store database credentials
fnox set PGHOST "db.example.com"
fnox set PGUSER "admin"
fnox set PGPASSWORD "secure-password"
fnox set PGDATABASE "production"

# Connect — psql reads PG* env vars automatically
fnox exec -- psql

# Or with a specific profile
fnox set --profile work PGHOST "work-db.internal"
fnox --profile work exec -- psql
```

### Example 3: Kubernetes / k3s Setup

```bash
# Store kubeconfig
fnox set KUBECONFIG_K3S "$(cat ~/.kube/config)"

# Use kubeconfig
fnox exec -- bash -c 'echo "$KUBECONFIG_K3S" > /tmp/kube.conf && kubectl --kubeconfig=/tmp/kube.conf get pods'

# Store SSH key for k3s nodes
fnox set SSHKEY_K3S "$(cat ~/.ssh/k3s_key)"
```

### Example 4: OCI CLI Configuration

```bash
# Your OCI credentials are already in the oci_aysesmenn profile
fnox --profile oci_aysesmenn exec -- oci iam region list

# List compute instances
fnox --profile oci_aysesmenn exec -- oci compute instance list \
    --compartment-id $OCI_TENANCY_OCID
```

### Example 5: Terraform with Cloudflare

```bash
# Terraform variables stored as secrets
fnox set TF_VAR_cloudflared_token "your-tunnel-token"

# Run terraform with secrets
fnox exec -- terraform plan
fnox exec -- terraform apply
```

### Example 6: SSH Key Management

```bash
# Store SSH private key
fnox set SSH_PRIVATE_KEY "$(cat ~/.ssh/id_ed25519)"

# Restore SSH key from fnox
fnox exec -- bash -c 'echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519 && chmod 600 ~/.ssh/id_ed25519'
```

### Best Practice: Security Rules

```
✅ DO:
• Back up key.txt in 2+ places (password manager + USB/paper)
• Use profiles to isolate contexts (personal / work / cloud)
• Commit fnox.toml to git (encrypted values are safe)
• Set chmod 600 key.txt, chmod 700 ~/.config/fnox/
• Rotate secrets quarterly
• Test restores regularly

❌ DON'T:
• Never commit key.txt to git
• Never share the private key
• Never store secrets in plain text (.env files)
• Never reuse the same secret across environments
```

---

## Post-Setup Checklist

After completing the bootstrap and fnox setup, verify everything:

```bash
# ┌─────────────────────────────────────────────────┐
# │             VERIFICATION CHECKLIST               │
# └─────────────────────────────────────────────────┘

echo "--- Tools ---"
mise list | head -5
echo "..."

echo "--- Shell ---"
starship --version
echo "Aliases: $(alias | wc -l)"

echo "--- Git ---"
git config user.name
git config user.email

echo "--- Chezmoi ---"
chezmoi doctor 2>&1 | grep -E "^(ok|error)"

echo "--- fnox ---"
fnox list 2>/dev/null && echo "✓ fnox working" || echo "✗ fnox: restore key.txt first"

echo "--- SSH ---"
ls -la ~/.ssh/config && echo "✓ SSH config exists" || echo "✗ SSH config missing"
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Bootstrap fresh system | `curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh \| bash` |
| Reload shell | `source ~/.bashrc` |
| Restore fnox key | `cp backup/key.txt ~/.config/fnox/key.txt && chmod 600 ~/.config/fnox/key.txt` |
| Verify secrets | `fnox list` |
| Set a secret | `fnox set KEY "value"` |
| Get a secret | `fnox get KEY` |
| Run with secrets | `fnox exec -- command` |
| Update dotfiles | `chezmoi update` |
| Test in Docker | `make shell` |
| Test in OrbStack | `orb create ubuntu devenv && orb -m devenv` |
| Clean OrbStack VM | `orb delete devenv` |
| Clean Docker | `make clean` |

---

**Last Updated:** 2026-02-19
