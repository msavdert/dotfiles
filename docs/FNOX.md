# FNOX Complete Usage Guide

Complete guide for managing secrets with fnox + age encryption in your dotfiles.

## Table of Contents
1. [What is FNOX?](#what-is-fnox)
2. [Initial Setup](#initial-setup)
3. [Basic Usage](#basic-usage)
4. [Backup & Restore](#backup--restore)
5. [Zero-to-Production Setup](#zero-to-production-setup)
6. [Advanced Usage](#advanced-usage)
7. [Troubleshooting](#troubleshooting)
8. [Security Best Practices](#security-best-practices)

---

## What is FNOX?

**fnox** is a secret management tool that:
- Encrypts secrets using **age** (modern encryption)
- Stores encrypted secrets in `fnox.toml` (safe to commit to git)
- Supports multiple encryption providers (age, AWS KMS, Azure Key Vault, etc.)
- Provides easy CLI for secret management
- Integrates with shell for automatic secret loading

**Why fnox + age?**
- ✅ Simple and secure encryption
- ✅ No external dependencies or cloud services needed
- ✅ Encrypted secrets safe to commit to public repos
- ✅ Private keys stay local (never committed)
- ✅ Easy backup and restore

---

## Initial Setup

### 1. Install Tools

```bash
# Install via mise (recommended)
mise install fnox age

# Or install directly
curl -fsSL https://fnox.jdx.dev/install.sh | sh
brew install age  # or: apt install age
```

### 2. Generate Age Encryption Key

```bash
# Create fnox config directory
mkdir -p ~/.config/fnox

# Generate age keypair
age-keygen -o ~/.config/fnox/key.txt

# Your output will look like:
# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
# (save this public key!)
```

**⚠️ CRITICAL: Save your age key securely!**
```bash
# Display your keys
cat ~/.config/fnox/key.txt

# Output:
# AGE-SECRET-KEY-1QYQSZQGPQYQSZQGPQYQSZQGPQYQSZQGPQYQSZQGPQYQSZQGPQYQSZ
# (This is your PRIVATE key - never share or commit!)

# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
# (This is your PUBLIC key - use for encryption)
```

### 3. Configure fnox.toml

Edit `fnox.toml` in your dotfiles root:

```toml
# fnox.toml
version = 1

[providers]
age = { recipients = [
    "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"  # Your public key
]}

[secrets]
# Database credentials
# DB_HOST = "encrypted:..."
# DB_USER = "encrypted:..."
# DB_PASSWORD = "encrypted:..."

# API keys
# AWS_ACCESS_KEY = "encrypted:..."
# GITHUB_TOKEN = "encrypted:..."

[profiles.development]
# profile-specific secrets

[profiles.production]
# profile-specific secrets
```

### 4. Initialize fnox

```bash
# Initialize (creates fnox.toml if not exists)
fnox init

# Verify setup
fnox list
```

---

## Basic Usage

### Adding Secrets

```bash
# Set a simple secret
fnox set DB_PASSWORD "my-secure-password"

# Set from stdin (for multiline secrets)
cat ~/.ssh/id_rsa | fnox set SSH_PRIVATE_KEY

# Set from file
fnox set API_KEY "$(cat api-key.txt)"

# Set multiple secrets
fnox set DB_HOST "db.example.com" \
         DB_USER "admin" \
         DB_PORT "5432"
```

### Reading Secrets

```bash
# Get a secret value
fnox get DB_PASSWORD

# List all secret names (not values)
fnox list

# Show all secrets (decrypted)
fnox show

# Export secrets as environment variables
fnox export
# Output: export DB_PASSWORD="my-secure-password"

# Load secrets into current shell
eval "$(fnox export)"
```

### Running Commands with Secrets

```bash
# Run command with secrets loaded
fnox exec -- psql -h $DB_HOST -U $DB_USER

# Run script with secrets
fnox exec -- ./deploy.sh

# Open interactive shell with secrets
fnox exec -- bash
```

### Editing Secrets

```bash
# Edit fnox.toml directly (encrypted values preserved)
fnox edit

# Remove a secret
fnox unset API_KEY

# Update a secret
fnox set DB_PASSWORD "new-password"
```

---

## Backup & Restore

### Critical Files to Backup

1. **Private Age Key** (NEVER COMMIT TO GIT)
   - Location: `~/.config/fnox/key.txt`
   - Contains: Private key + Public key
   - Critical: Required to decrypt all secrets

2. **fnox.toml** (SAFE TO COMMIT)
   - Location: `~/dotfiles/fnox.toml`
   - Contains: Encrypted secrets
   - Safe: Can be public

### Backup Strategy

#### Option 1: Manual Backup (Recommended for Personal Use)

```bash
# 1. Backup age private key securely
# Method A: Encrypted USB drive
cp ~/.config/fnox/key.txt /media/usb-backup/fnox-key-backup-$(date +%Y%m%d).txt

# Method B: Encrypted cloud storage (after encrypting)
age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p \
    -o ~/Dropbox/backups/fnox-key-backup-$(date +%Y%m%d).txt.age \
    ~/.config/fnox/key.txt

# Method C: Password manager (1Password, Bitwarden, etc.)
# Copy content to secure note in password manager
cat ~/.config/fnox/key.txt

# 2. Backup fnox.toml (already in git)
# This is already backed up in your dotfiles repo
# Just ensure it's committed:
cd ~/dotfiles
git add fnox.toml
git commit -m "chore: update encrypted secrets"
git push
```

#### Option 2: Print Paper Backup

```bash
# Print age key to paper (store in safe)
echo "=== FNOX AGE KEY BACKUP ===" > fnox-backup.txt
echo "Date: $(date)" >> fnox-backup.txt
echo "" >> fnox-backup.txt
cat ~/.config/fnox/key.txt >> fnox-backup.txt
echo "" >> fnox-backup.txt
echo "Public key for reference:" >> fnox-backup.txt
grep "public key:" ~/.config/fnox/key.txt >> fnox-backup.txt

# Print and store securely
lpr fnox-backup.txt  # or manually copy to paper
shred -u fnox-backup.txt  # secure delete
```

#### Option 3: Split Key Backup (Extra Security)

```bash
# Split key into 3 parts (need 2 of 3 to recover)
ssss-split -t 2 -n 3 < ~/.config/fnox/key.txt

# Store each part in different locations:
# - Part 1: USB drive in safe
# - Part 2: Password manager
# - Part 3: Trusted family member
```

### Restore from Backup

#### Scenario 1: New Machine with Backup

```bash
# 1. Install tools
mise install fnox age

# 2. Restore age key
mkdir -p ~/.config/fnox
chmod 700 ~/.config/fnox

# From USB backup
cp /media/usb-backup/fnox-key-backup-20250115.txt ~/.config/fnox/key.txt

# Or from encrypted cloud backup
age -d -i /path/to/master-key.txt \
    -o ~/.config/fnox/key.txt \
    ~/Dropbox/backups/fnox-key-backup-20250115.txt.age

# Set correct permissions
chmod 600 ~/.config/fnox/key.txt

# 3. Verify key
cat ~/.config/fnox/key.txt
# Should show: AGE-SECRET-KEY-... and public key

# 4. Clone dotfiles (fnox.toml included)
git clone https://github.com/msavdert/dotfiles.git ~/.local/share/chezmoi

# 5. Test decryption
cd ~/.local/share/chezmoi
fnox list
fnox get DB_PASSWORD  # Should decrypt successfully
```

#### Scenario 2: Lost Key, Have Paper Backup

```bash
# 1. Type key from paper
mkdir -p ~/.config/fnox
nano ~/.config/fnox/key.txt
# (carefully type AGE-SECRET-KEY-... from paper)

# 2. Verify format
cat ~/.config/fnox/key.txt
# Should be exactly:
# AGE-SECRET-KEY-1QYQSZQGPQYQSZQGPQYQSZQGPQYQSZQGPQYQSZQGPQYQSZQGPQYQSZ

# 3. Set permissions
chmod 600 ~/.config/fnox/key.txt

# 4. Test
fnox get DB_PASSWORD
```

#### Scenario 3: Compromised Key (Recovery)

```bash
# 1. Generate NEW age key
mv ~/.config/fnox/key.txt ~/.config/fnox/key.txt.old
age-keygen -o ~/.config/fnox/key.txt

# 2. Get new public key
grep "public key:" ~/.config/fnox/key.txt
# New: age1abc...

# 3. Re-encrypt all secrets
cd ~/dotfiles

# Export all secrets using OLD key
FNOX_AGE_KEY=~/.config/fnox/key.txt.old fnox export > /tmp/secrets.env

# Update fnox.toml with NEW public key
sed -i 's/age1old.../age1abc.../' fnox.toml

# Clear all encrypted values
fnox clear-all

# Import secrets with NEW key
source /tmp/secrets.env
fnox set DB_PASSWORD "$DB_PASSWORD"
fnox set DB_USER "$DB_USER"
# ... (repeat for all secrets)

# 4. Clean up
shred -u /tmp/secrets.env
rm ~/.config/fnox/key.txt.old

# 5. Commit updated fnox.toml
git add fnox.toml
git commit -m "security: rotate age encryption key"
git push
```

---

## Zero-to-Production Setup

Complete guide to setting up secrets on a brand new machine.

### Phase 1: Tool Installation

```bash
# 1. Run dotfiles bootstrap
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash

# This installs:
# - mise
# - chezmoi
# - fnox + age
# - all dotfiles

# 2. Verify installation
which fnox age
fnox --version
age --version
```

### Phase 2: Key Restoration

```bash
# 3. Restore age key from backup
mkdir -p ~/.config/fnox
chmod 700 ~/.config/fnox

# Copy from secure backup (choose method):
# Method A: From USB
cp /media/usb/fnox-key-backup.txt ~/.config/fnox/key.txt

# Method B: From password manager (paste content)
nano ~/.config/fnox/key.txt
# (paste content, Ctrl+X, Y, Enter)

# Method C: From encrypted backup
age -d -i /path/to/master-key.txt \
    -o ~/.config/fnox/key.txt \
    ~/backup/fnox-key.age

# 4. Set permissions
chmod 600 ~/.config/fnox/key.txt

# 5. Verify key
cat ~/.config/fnox/key.txt | head -n 1
# Should start with: AGE-SECRET-KEY-
```

### Phase 3: Verify Secret Access

```bash
# 6. Test secret decryption
cd ~/.local/share/chezmoi
fnox list
# Should show all secret names

fnox get DB_PASSWORD
# Should decrypt and show value

# 7. Load secrets into shell
eval "$(fnox export)"
echo $DB_PASSWORD
# Should show decrypted value
```

### Phase 4: Production Secrets

```bash
# 8. Add production-specific secrets
fnox set --profile production DB_HOST "prod-db.example.com"
fnox set --profile production DB_PASSWORD "prod-secure-pass"
fnox set --profile production API_KEY "prod-api-key"

# 9. Test production profile
fnox --profile production list
fnox --profile production get DB_HOST

# 10. Run production command
fnox --profile production exec -- ./deploy-prod.sh
```

### Phase 5: Verification Checklist

```bash
# ✓ Age key exists and readable
[ -f ~/.config/fnox/key.txt ] && echo "✓ Age key found" || echo "✗ Age key missing"

# ✓ fnox.toml exists
[ -f ~/.local/share/chezmoi/fnox.toml ] && echo "✓ fnox.toml found" || echo "✗ fnox.toml missing"

# ✓ Can list secrets
fnox list >/dev/null 2>&1 && echo "✓ Can list secrets" || echo "✗ Cannot list secrets"

# ✓ Can decrypt secrets
fnox get DB_PASSWORD >/dev/null 2>&1 && echo "✓ Can decrypt secrets" || echo "✗ Cannot decrypt"

# ✓ Public key matches
PUBLIC_KEY=$(grep "public key:" ~/.config/fnox/key.txt | cut -d: -f2 | tr -d ' ')
grep -q "$PUBLIC_KEY" ~/.local/share/chezmoi/fnox.toml && echo "✓ Public key matches" || echo "✗ Public key mismatch"
```

---

## Advanced Usage

### Profile Management

```bash
# Different secrets for different environments
[profiles.development]
DB_HOST = "encrypted:dev-host..."
DB_PASSWORD = "encrypted:dev-pass..."

[profiles.staging]
DB_HOST = "encrypted:staging-host..."
DB_PASSWORD = "encrypted:staging-pass..."

[profiles.production]
DB_HOST = "encrypted:prod-host..."
DB_PASSWORD = "encrypted:prod-pass..."

# Use profiles
fnox --profile development get DB_HOST
fnox --profile production exec -- ./deploy.sh
```

### Multiple Recipients

```bash
# Share secrets with team members
[providers]
age = { recipients = [
    "age1ql3z...my-key",      # Your key
    "age1abc...teammate1",    # Teammate 1
    "age1xyz...teammate2"     # Teammate 2
]}

# All recipients can decrypt
```

### Secret Rotation

```bash
# Rotate database password
NEW_PASS=$(openssl rand -base64 32)
fnox set DB_PASSWORD "$NEW_PASS"

# Update database
psql -h $DB_HOST -U postgres -c "ALTER USER $DB_USER PASSWORD '$NEW_PASS';"

# Commit rotated secret
git add fnox.toml
git commit -m "security: rotate DB password"
git push
```

### Import/Export

```bash
# Export all secrets to file (CAREFUL!)
fnox export > /tmp/secrets.env

# Import from env file
source /tmp/secrets.env
fnox set DB_HOST "$DB_HOST"
fnox set DB_USER "$DB_USER"

# Clean up
shred -u /tmp/secrets.env
```

---

## Troubleshooting

### Cannot Decrypt Secrets

```bash
# Check age key exists
ls -la ~/.config/fnox/key.txt

# Check permissions
# Should be: -rw------- (600)
chmod 600 ~/.config/fnox/key.txt

# Verify key format
head -n 1 ~/.config/fnox/key.txt
# Should start with: AGE-SECRET-KEY-

# Test age directly
echo "test" | age -r $(grep "public key:" ~/.config/fnox/key.txt | cut -d: -f2 | tr -d ' ') | \
    age -d -i ~/.config/fnox/key.txt
# Should output: test
```

### Public Key Mismatch

```bash
# Get public key from private key
age-keygen -y ~/.config/fnox/key.txt
# Output: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

# Update fnox.toml
nano fnox.toml
# Update recipients = ["age1ql3z..."] with correct key

# Re-encrypt all secrets (see "Compromised Key Recovery" section)
```

### Lost All Secrets

```bash
# If you have age key but fnox.toml is empty/lost:

# 1. Check git history
cd ~/dotfiles
git log --all --full-history -- fnox.toml
git show <commit-hash>:fnox.toml > fnox.toml

# 2. Check backups
ls -ltr ~/backups/*fnox*

# 3. Re-create from documentation
# Manually re-enter secrets (last resort)
fnox set DB_PASSWORD "..."
```

---

## Security Best Practices

### DO ✅

1. **Backup age key regularly**
   - Multiple locations (USB, password manager, paper)
   - Test restores periodically

2. **Use strong permissions**
   ```bash
   chmod 600 ~/.config/fnox/key.txt
   chmod 700 ~/.config/fnox
   ```

3. **Commit fnox.toml**
   - Encrypted secrets are safe in git
   - Easy to restore/share

4. **Rotate secrets periodically**
   - Database passwords: quarterly
   - API keys: when compromised
   - SSH keys: yearly

5. **Use profiles for environments**
   - Separate dev/staging/prod secrets
   - Prevent accidents

6. **Review secrets regularly**
   ```bash
   fnox list  # What secrets do I have?
   ```

### DON'T ❌

1. **Never commit age private key**
   ```bash
   # Add to .gitignore
   .config/fnox/key.txt
   ```

2. **Never share private key**
   - Share public key instead
   - Add as recipient in fnox.toml

3. **Never store secrets in plain text**
   ```bash
   # Bad
   echo "password123" > password.txt
   
   # Good
   fnox set DB_PASSWORD "password123"
   ```

4. **Never use weak encryption**
   - age is modern and strong
   - Don't use base64 encoding (not encryption!)

5. **Never skip backups**
   - Lost key = lost secrets permanently
   - No recovery without key

### Incident Response

```bash
# If age key is compromised:
# 1. Generate new key immediately
# 2. Re-encrypt all secrets
# 3. Rotate all actual secrets (DB passwords, API keys, etc.)
# 4. Audit access logs
# 5. Document incident

# See "Scenario 3: Compromised Key Recovery" section above
```

---

## Integration Examples

### PostgreSQL Connection

```bash
# Store credentials
fnox set PGHOST "db.example.com"
fnox set PGUSER "dba"
fnox set PGPASSWORD "secure-pass"
fnox set PGDATABASE "mydb"

# Connect using fnox
fnox exec -- psql
# Or
eval "$(fnox export)" && psql
```

### Kubernetes Secrets

```bash
# Store kubeconfig
fnox set KUBECONFIG "$(cat ~/.kube/config)"

# Use with kubectl
fnox exec -- kubectl get pods

# Or create k8s secret from fnox
fnox get DB_PASSWORD | kubectl create secret generic db-secret --from-file=password=/dev/stdin
```

### CI/CD Integration

```bash
# GitHub Actions
# 1. Store age key as GitHub secret: FNOX_AGE_KEY
# 2. In workflow:
- name: Setup secrets
  run: |
    mkdir -p ~/.config/fnox
    echo "${{ secrets.FNOX_AGE_KEY }}" > ~/.config/fnox/key.txt
    chmod 600 ~/.config/fnox/key.txt
    eval "$(fnox export)"
```

---

## Quick Reference

```bash
# Setup
age-keygen -o ~/.config/fnox/key.txt     # Generate key
fnox init                                 # Initialize

# Basic operations
fnox set KEY "value"                      # Add secret
fnox get KEY                              # Read secret
fnox list                                 # List all secrets
fnox unset KEY                            # Remove secret

# Usage
fnox exec -- command                      # Run with secrets
eval "$(fnox export)"                     # Load into shell
fnox --profile prod get KEY               # Use profile

# Backup
cp ~/.config/fnox/key.txt /backup/        # Backup key
git add fnox.toml && git commit && git push  # Backup secrets

# Restore
cp /backup/key.txt ~/.config/fnox/        # Restore key
chmod 600 ~/.config/fnox/key.txt          # Fix permissions
git clone ... && fnox list                # Verify
```

---

## Additional Resources

- [fnox Documentation](https://fnox.jdx.dev/)
- [age Encryption](https://age-encryption.org/)
- [Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Dotfiles Guide](../README.md)

---

**Last Updated:** 2025-01-20  
**Author:** msavdert
