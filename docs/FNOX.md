# fnox — Secret Management Guide

Practical guide for managing secrets with [fnox](https://fnox.jdx.dev/) + [age](https://age-encryption.org/) encryption.

## How It Works

```
┌──────────────┐    age encrypt    ┌──────────────┐
│  Plain Text  │ ──────────────► │  fnox.toml   │  ← Safe to commit
│  (secrets)   │                  │  (encrypted) │
└──────────────┘    age decrypt    └──────────────┘
       ▲         ◄──────────────         │
       │              │                  │
       │     ~/.config/fnox/age.txt      │
       │     (PRIVATE - never commit)    │
```

- **fnox.toml** — encrypted secrets, safe in git ✅
- **age.txt** — private age key, never commit ❌

## Initial Setup

### 1. Generate Age Key

```bash
mkdir -p ~/.config/fnox && chmod 700 ~/.config/fnox
age-keygen -o ~/.config/fnox/age.txt
chmod 600 ~/.config/fnox/age.txt

# Output shows your PUBLIC key — save it:
# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

### 2. Initialize fnox

```bash
# Interactive wizard (recommended)
fnox init

# Or create fnox.toml manually:
cat > fnox.toml << EOF
[providers]
age = { type = "age", recipients = ["$(age-keygen -y ~/.config/fnox/age.txt)"] }

[secrets]
EOF
```

### 3. Verify

```bash
fnox set TEST_SECRET "hello"
fnox get TEST_SECRET   # Should output: hello
fnox unset TEST_SECRET
```

## Daily Usage

### Managing Secrets

```bash
# Set
fnox set DB_PASSWORD "my-secure-password"
fnox set SSH_KEY "$(cat ~/.ssh/id_rsa)"          # Multiline from file

# Get
fnox get DB_PASSWORD

# List (names only, no values)
fnox list

# Remove
fnox unset OLD_SECRET

# Edit all secrets in editor
fnox edit
```

### Using Secrets

```bash
# Run a command with secrets injected as env vars
fnox exec -- psql -h $DB_HOST -U $DB_USER

# Load into current shell
eval "$(fnox export)"

# Use in scripts
fnox exec -- ./deploy.sh
```

### Profiles (Environment Separation)

```bash
# Set secrets for a specific profile
fnox set --profile production DB_HOST "prod-db.example.com"

# Use a specific profile
fnox --profile production get DB_HOST
fnox --profile production exec -- ./deploy.sh
```

## Backup & Restore

### What to Backup

| File | Location | In Git? | Priority |
|------|----------|---------|----------|
| `age.txt` | `~/.config/fnox/age.txt` | ❌ Never | 🔴 Critical |
| `fnox.toml` | Repo root | ✅ Yes | 🟢 Already backed up |

> **⚠️ Lost key = lost secrets permanently.** There is no recovery without the private key.

### Backup Methods

```bash
# Method 1: Password manager (recommended)
cat ~/.config/fnox/age.txt
# Copy entire content to a secure note in 1Password/Bitwarden

# Method 2: Encrypted USB
cp ~/.config/fnox/age.txt /Volumes/SECURE-USB/fnox-key-$(date +%Y%m%d).txt

# Method 3: Paper backup (last resort)
cat ~/.config/fnox/age.txt
# Write down the AGE-SECRET-KEY-... line, store in safe
```

### Restore on New Machine

```bash
# 1. Run dotfiles bootstrap
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash

# 2. Restore age key from backup
mkdir -p ~/.config/fnox && chmod 700 ~/.config/fnox
# Paste from password manager, or copy from USB:
cp /Volumes/SECURE-USB/fnox-age.txt ~/.config/fnox/age.txt
chmod 600 ~/.config/fnox/age.txt

# 3. Verify
fnox list              # Should list all secret names
fnox get DB_PASSWORD   # Should decrypt successfully
```

### Key Rotation (If Compromised)

```bash
# 1. Export all secrets with OLD key
fnox export > /tmp/secrets.env

# 2. Generate NEW key
mv ~/.config/fnox/age.txt ~/.config/fnox/age.txt.old
age-keygen -o ~/.config/fnox/age.txt
chmod 600 ~/.config/fnox/age.txt

# 3. Re-encrypt all secrets with NEW key
# Update recipient in fnox.toml with new public key
# Then re-set each secret from the exported values

# 4. Securely delete exports
shred -u /tmp/secrets.env
rm ~/.config/fnox/age.txt.old

# 5. Rotate actual credentials (DB passwords, API keys, etc.)
# 6. Commit updated fnox.toml
```

## Integration Examples

### PostgreSQL

```bash
fnox set PGHOST "db.example.com"
fnox set PGUSER "dba"
fnox set PGPASSWORD "secure-pass"
fnox exec -- psql -d mydb
```

### Kubernetes

```bash
fnox set KUBECONFIG_DATA "$(cat ~/.kube/config)"
fnox exec -- kubectl get pods
```

### GitHub CLI

```bash
fnox exec -- echo ${GITHUB_TOKEN_GENERAL} | gh auth login --with-token
# Or use the mise task: mise run ghl-gen
```

### SSH via fnox

```bash
fnox set SSH_PRIVATE_KEY "$(cat ~/.ssh/id_rsa)"
fnox exec -- ssh -i <(echo "$SSH_PRIVATE_KEY") user@host
```

## Security Best Practices

### ✅ Do

- Back up `age.txt` in **multiple locations** (password manager + USB)
- Set strict permissions: `chmod 600 age.txt`, `chmod 700 ~/.config/fnox/`
- Commit `fnox.toml` to git (encrypted values are safe)
- Use profiles to separate dev/staging/prod
- Rotate secrets periodically
- Test restores from backup regularly

### ❌ Don't

- Never commit `age.txt` to git
- Never share the private key
- Never store secrets in plain text files
- Never use the same credentials across environments
- Never skip backups

## Aliases

| Alias | Command |
|-------|---------|
| `fe` | `fnox edit` |
| `fg` | `fnox get` |
| `fs` | `fnox set` |
| `fl` | `fnox list` |
| `fx` | `fnox exec` |

## Troubleshooting

```bash
# Check key exists and has correct permissions
ls -la ~/.config/fnox/age.txt   # Should be -rw-------

# Verify key format
head -n 1 ~/.config/fnox/age.txt  # Should start with AGE-SECRET-KEY-

# Get public key from private key
age-keygen -y ~/.config/fnox/age.txt

# Test age encryption/decryption directly
echo "test" | age -r $(age-keygen -y ~/.config/fnox/age.txt) | \
    age -d -i ~/.config/fnox/age.txt
# Should output: test
```

## Resources

- [fnox Documentation](https://fnox.jdx.dev/)
- [age Encryption](https://age-encryption.org/)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Last Updated:** 2026-02-18
