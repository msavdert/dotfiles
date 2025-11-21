# CHEZMOI Complete Usage Guide

Complete guide for managing dotfiles with chezmoi, synchronization workflows, and container integration.

## Table of Contents
1. [What is CHEZMOI?](#what-is-chezmoi)
2. [Initial Setup](#initial-setup)
3. [Local Changes Workflow](#local-changes-workflow)
4. [Git Synchronization](#git-synchronization)
5. [Container Workflow](#container-workflow)
6. [Multi-Machine Synchronization](#multi-machine-synchronization)
7. [Advanced Usage](#advanced-usage)
8. [Troubleshooting](#troubleshooting)

---

## What is CHEZMOI?

**chezmoi** is a dotfile manager that:
- Manages your dotfiles across multiple machines
- Supports templates for machine-specific configurations
- Tracks changes in git
- Handles file encryption for private files
- Provides easy sync between machines

**Why chezmoi?**
- ✅ Single source of truth for dotfiles
- ✅ Machine-specific configurations
- ✅ Easy to sync changes
- ✅ Safe to use with encryption
- ✅ Handles permissions correctly

---

## Initial Setup

### First Time Setup

```bash
# 1. Install chezmoi (via mise)
mise install chezmoi

# 2. Initialize with your dotfiles repo
chezmoi init https://github.com/msavdert/dotfiles.git

# This creates:
# ~/.local/share/chezmoi/  (source state - your dotfiles repo)
# ~/.config/chezmoi/       (chezmoi config)

# 3. Review changes before applying
chezmoi diff

# 4. Apply dotfiles
chezmoi apply

# 5. Verify
ls -la ~/ | grep -E "bashrc|bash_aliases|gitconfig"
```

### Directory Structure

```
~/.local/share/chezmoi/           # Source state (git repo)
├── dot_bashrc                     # → ~/.bashrc
├── dot_bash_aliases               # → ~/.bash_aliases
├── dot_bash_profile               # → ~/.bash_profile
├── dot_gitconfig                  # → ~/.gitconfig
├── dot_config/
│   ├── mise/
│   │   └── config.toml            # → ~/.config/mise/config.toml
│   ├── fnox/
│   │   └── config.toml            # → ~/.config/fnox/config.toml
│   ├── starship.toml              # → ~/.config/starship.toml
│   └── zellij/
│       └── config.kdl             # → ~/.config/zellij/config.kdl
├── private_dot_ssh/
│   ├── config.tmpl                # → ~/.ssh/config
│   └── private_readonly_id_ed25519_github.age  # → ~/.ssh/id_ed25519_github (mode 0400)
├── .chezmoiignore
├── install.sh
└── README.md
```

**File naming conventions:**
- `dot_` → `.` (hidden file)
- `private_` → not readable by others (mode 0600)
- `readonly_` → not writable (mode 0400)
- `executable_` → executable (mode 0755)
- `.tmpl` → template (processed)

---

## Local Changes Workflow

### Scenario 1: Edit Existing Dotfile

```bash
# Method A: Edit through chezmoi (recommended)
chezmoi edit ~/.bashrc

# This opens ~/.local/share/chezmoi/dot_bashrc in $EDITOR
# Make your changes, save, and exit

# Preview changes
chezmoi diff

# Apply changes to home directory
chezmoi apply

# Method B: Direct edit (NOT recommended)
nano ~/.bashrc
# Make changes

# Import changes back to chezmoi
chezmoi add ~/.bashrc

# Now source is updated at ~/.local/share/chezmoi/dot_bashrc
```

### Scenario 2: Add New Dotfile

```bash
# Create new config file
mkdir -p ~/.config/myapp
echo "setting=value" > ~/.config/myapp/config.ini

# Add to chezmoi
chezmoi add ~/.config/myapp/config.ini

# File added to: ~/.local/share/chezmoi/dot_config/myapp/config.ini

# Commit to git
cd ~/.local/share/chezmoi
git add dot_config/myapp/config.ini
git commit -m "feat: add myapp configuration"
git push
```

### Scenario 3: Quick Edit & Apply

```bash
# Edit and apply in one step
chezmoi edit --apply ~/.bash_aliases

# This:
# 1. Opens editor
# 2. Waits for you to save
# 3. Automatically applies changes to ~/.bash_aliases
```

### Scenario 4: Remove Dotfile

```bash
# Remove from chezmoi management
chezmoi forget ~/.config/oldapp/config

# Or completely remove
chezmoi forget ~/.config/oldapp/config
rm ~/.config/oldapp/config

# Remove from source
cd ~/.local/share/chezmoi
git rm dot_config/oldapp/config
git commit -m "chore: remove oldapp config"
git push
```

---

## Git Synchronization

### Understanding the Sync Model

```
┌─────────────────────────────────────────────────────────────────┐
│                     Synchronization Flow                         │
└─────────────────────────────────────────────────────────────────┘

Local Machine                    GitHub                    Remote Machine
─────────────────                ──────                    ──────────────

~/.bashrc                                                  ~/.bashrc
    ↑                                                          ↑
    │ chezmoi apply                                           │ chezmoi apply
    │                                                          │
~/.local/share/chezmoi/     ←→    github.com/msavdert/    ←→  ~/.local/share/chezmoi/
dot_bashrc                   dotfiles                    dot_bashrc
    │                                                          ↑
    │ git commit + push          (git repo)                   │ git pull
    │                                                          │
    └──────────────────────────────┬──────────────────────────┘
                                   │
                          Changes propagate via git
```

### Workflow: Local Changes → Git → Other Machines

#### Step 1: Make Changes Locally

```bash
# On your laptop
chezmoi edit ~/.bashrc
# Add: export LAPTOP_SETTING="value"

# Apply locally
chezmoi apply

# Test
source ~/.bashrc
echo $LAPTOP_SETTING
```

#### Step 2: Commit to Git

```bash
# Go to source directory
cd ~/.local/share/chezmoi

# Check what changed
git status
git diff dot_bashrc

# Stage changes
git add dot_bashrc

# Commit with descriptive message
git commit -m "feat: add laptop-specific setting to bashrc"

# Push to GitHub
git push origin main
```

#### Step 3: Pull on Other Machines

```bash
# On your desktop/server
cd ~/.local/share/chezmoi

# Pull latest changes
git pull origin main

# Review what changed
chezmoi diff

# Apply changes
chezmoi apply

# Verify
source ~/.bashrc
```

### Workflow: Multiple Changes at Once

```bash
# Make multiple changes
chezmoi edit --apply ~/.bashrc
chezmoi edit --apply ~/.bash_aliases
chezmoi add ~/.config/newapp/config

# Go to source
cd ~/.local/share/chezmoi

# Review all changes
git status
git diff

# Commit all at once
git add .
git commit -m "feat: update bash config and add newapp config

- Add LAPTOP_SETTING to bashrc
- Add new aliases for docker management
- Add newapp configuration"

# Push
git push
```

### Safe Sync Pattern (Recommended)

```bash
# 1. Always pull before making changes
cd ~/.local/share/chezmoi
git pull origin main
chezmoi apply

# 2. Make your changes
chezmoi edit --apply ~/.bashrc

# 3. Commit and push
cd ~/.local/share/chezmoi
git add .
git commit -m "feat: your changes"
git push

# 4. On other machines, pull and apply
cd ~/.local/share/chezmoi
git pull origin main
chezmoi diff  # Review changes
chezmoi apply
```

---

## Container Workflow

### Understanding Container Persistence

```
┌─────────────────────────────────────────────────────────────────┐
│              Container Dotfiles Workflow                         │
└─────────────────────────────────────────────────────────────────┘

Host Machine                    Container
────────────                    ─────────

~/Documents/all/github/dotfiles/    →    /home/msavdert/dotfiles/
(bind mount - live sync)                 (same files, instant sync)

Changes in container appear immediately on host
Changes on host appear immediately in container
```

### Docker Compose Setup

Your `docker-compose.yml`:

```yaml
services:
  dotfiles:
    build: .
    volumes:
      - .:/home/msavdert/dotfiles  # Bind mount - bidirectional sync
    working_dir: /home/msavdert/dotfiles
    command: tail -f /dev/null
```

**This means:**
- ✅ Edit files on host → instantly available in container
- ✅ Edit files in container → instantly on host
- ✅ git operations work from both sides
- ⚠️ Container is ephemeral - only mounted directory persists

### Workflow: Testing Changes in Container

#### Method 1: Edit on Host, Test in Container

```bash
# 1. Start container
cd ~/Documents/all/github/dotfiles
docker compose up -d

# 2. Edit on host (your IDE/editor)
code ~/Documents/all/github/dotfiles/dot_bashrc
# Make changes, save

# 3. Test in container immediately
docker compose exec dotfiles bash

# Changes are already there (bind mount)
chezmoi diff
chezmoi apply
source ~/.bashrc

# 4. If good, commit on host
cd ~/Documents/all/github/dotfiles
git add dot_bashrc
git commit -m "feat: update bashrc"
git push
```

#### Method 2: Edit in Container, Commit from Host

```bash
# 1. Enter container
docker compose exec dotfiles bash

# 2. Make changes
chezmoi edit --apply ~/.bashrc

# 3. Exit container
exit

# 4. Commit from host (changes already synced via bind mount)
cd ~/Documents/all/github/dotfiles
git status  # Will show your container changes
git add .
git commit -m "feat: update bashrc"
git push
```

### Running Install Script in Container

**Question:** Is it harmful to run install.sh multiple times?

**Answer:** **No, it's safe and idempotent.** Here's why:

```bash
# The install script checks before installing
if command -v mise &> /dev/null; then
    echo "mise already installed"
else
    echo "Installing mise..."
    curl https://mise.run | sh
fi

# Same for other tools
mise install  # Only installs missing tools
chezmoi init  # Only initializes if not already done
```

**Multiple runs will:**
- ✅ Skip already installed tools
- ✅ Update to latest versions if specified
- ✅ Re-apply configurations
- ✅ Not break anything

**When to re-run:**
```bash
# 1. Testing changes to install.sh
docker compose exec dotfiles bash -c "curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash"

# 2. After adding new tool to mise.toml
docker compose exec dotfiles bash
mise install  # Just install new tools

# 3. After changing dotfiles
docker compose exec dotfiles bash
chezmoi apply  # Just apply dotfile changes
```

### Container Development Workflow

```bash
# Full workflow in one terminal session

# 1. Start container
cd ~/Documents/all/github/dotfiles
docker compose up -d

# 2. Enter container
docker compose exec dotfiles bash

# 3. Make changes (chezmoi or direct edit)
chezmoi edit ~/.bashrc

# 4. Apply and test
chezmoi apply
source ~/.bashrc
# Test your changes...

# 5. If good, exit container
exit

# 6. Commit from host
git add .
git commit -m "feat: your changes"
git push

# 7. Pull on production server
ssh prod-server
cd ~/.local/share/chezmoi
git pull
chezmoi apply
```

### Container State Management

```bash
# Container is ephemeral - only mounted directory persists

# What persists (in ~/Documents/all/github/dotfiles):
# ✅ All source files (home/*, mise.toml, etc.)
# ✅ Git history
# ✅ Changes you make

# What does NOT persist (container internal state):
# ❌ Installed tools (mise, chezmoi, fnox, etc.)
# ❌ Applied dotfiles in container's home directory
# ❌ Container's ~/.bashrc, ~/.config/*, etc.

# After container restart:
docker compose restart dotfiles
docker compose exec dotfiles bash
# You'll need to re-apply dotfiles:
chezmoi apply
source ~/.bashrc

# Or re-run install.sh (safe):
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
```

---

## Multi-Machine Synchronization

### Scenario: Laptop, Desktop, Multiple Servers

```bash
# Machine A (Laptop)
chezmoi edit ~/.bashrc  # Add new alias
cd ~/.local/share/chezmoi
git add . && git commit -m "feat: add alias" && git push

# Machine B (Desktop)
cd ~/.local/share/chezmoi
git pull
chezmoi diff  # Review changes
chezmoi apply

# Machine C (Server 1)
cd ~/.local/share/chezmoi
git pull && chezmoi apply

# Machine D (Server 2)
cd ~/.local/share/chezmoi
git pull && chezmoi apply
```

### Automated Sync with Cron

```bash
# Create sync script
cat > ~/.local/bin/chezmoi-sync.sh << 'EOF'
#!/bin/bash
cd ~/.local/share/chezmoi
git pull --rebase origin main
if [ $? -eq 0 ]; then
    chezmoi apply --force
    logger "chezmoi: synced dotfiles successfully"
else
    logger "chezmoi: failed to sync dotfiles"
fi
EOF

chmod +x ~/.local/bin/chezmoi-sync.sh

# Add to crontab (sync every hour)
crontab -e
# Add: 0 * * * * ~/.local/bin/chezmoi-sync.sh
```

### Machine-Specific Configurations

Use templates for machine-specific settings:

```bash
# In dot_bashrc.tmpl
export EDITOR="nvim"

{{ if eq .chezmoi.hostname "laptop" }}
export WORKSPACE="$HOME/Documents/workspace"
{{ else if eq .chezmoi.hostname "desktop" }}
export WORKSPACE="$HOME/work"
{{ else }}
export WORKSPACE="$HOME/projects"
{{ end }}

# On each machine, chezmoi applies the correct value
```

---

## Advanced Usage

### Chezmoi Data Variables

```bash
# View all available variables
chezmoi data

# Output:
# {
#   "chezmoi": {
#     "arch": "amd64",
#     "os": "linux",
#     "hostname": "my-laptop",
#     "username": "msavdert",
#     "homeDir": "/home/msavdert",
#     ...
#   }
# }

# Use in templates
{{ .chezmoi.hostname }}
{{ .chezmoi.os }}
{{ .chezmoi.arch }}
```

### Template Functions

```bash
# In dot_gitconfig.tmpl
[user]
    name = msavdert
{{ if eq .chezmoi.hostname "work-laptop" }}
    email = melih.savdert@company.com
{{ else }}
    email = 10913156+msavdert@users.noreply.github.com
{{ end }}

[core]
    editor = {{ .editor | default "nvim" }}
```

### Encrypted Files

```bash
# Add encrypted SSH key
chezmoi add --encrypt ~/.ssh/id_rsa

# Creates: home/private_encrypted_id_rsa.asc (GPG encrypted)

# On other machine:
chezmoi apply
# Prompts for GPG passphrase, decrypts to ~/.ssh/id_rsa
```

### Dry Run

```bash
# See what would change without applying
chezmoi apply --dry-run --verbose

# See differences
chezmoi diff
```

### Selective Apply

```bash
# Apply only specific files
chezmoi apply ~/.bashrc
chezmoi apply ~/.config/starship.toml

# Apply only files matching pattern
chezmoi apply --include "*.sh"
```

---

## Troubleshooting

### Merge Conflicts

```bash
# If git pull shows conflicts
cd ~/.local/share/chezmoi
git pull
# CONFLICT in dot_bashrc

# Resolve manually
nano dot_bashrc
# Fix conflicts, save

git add dot_bashrc
git commit -m "fix: resolve merge conflict"
git push

# Apply resolved version
chezmoi apply
```

### Out of Sync

```bash
# Local file different from source
chezmoi diff ~/.bashrc
# Shows differences

# Option 1: Use chezmoi version (discard local)
chezmoi apply --force

# Option 2: Keep local changes (update source)
chezmoi add ~/.bashrc
cd ~/.local/share/chezmoi
git commit -am "fix: update bashrc with local changes"
git push
```

### Permission Issues

```bash
# Fix file permissions
cd ~/.local/share/chezmoi

# Check current permissions
ls -la home/

# Fix permissions in source
chmod 755 dot_bashrc
chmod 600 home/private_dot_ssh/private_*

# Apply with correct permissions
chezmoi apply
```

### Reset Everything

```bash
# Nuclear option: start fresh
# 1. Backup current state
cd ~/.local/share/chezmoi
git stash
git log  # Note commit hash

# 2. Remove chezmoi
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi

# 3. Re-initialize
chezmoi init https://github.com/msavdert/dotfiles.git
chezmoi apply
```

---

## Daily Workflow Summary

### Morning Routine (Pull Latest)

```bash
# On each machine you use
cd ~/.local/share/chezmoi && git pull && chezmoi apply
```

### Making Changes

```bash
# 1. Edit
chezmoi edit --apply ~/.bashrc

# 2. Commit
cd ~/.local/share/chezmoi
git add . && git commit -m "feat: update bashrc" && git push

# 3. On other machines
cd ~/.local/share/chezmoi && git pull && chezmoi apply
```

### Container Testing

```bash
# 1. Edit on host
code ~/Documents/all/github/dotfiles/dot_bashrc

# 2. Test in container (changes already synced via bind mount)
docker compose exec dotfiles bash
chezmoi apply
source ~/.bashrc

# 3. Commit from host if good
cd ~/Documents/all/github/dotfiles
git add . && git commit -m "feat: update" && git push
```

---

## Best Practices

### DO ✅

1. **Always pull before editing**
   ```bash
   cd ~/.local/share/chezmoi && git pull
   ```

2. **Use chezmoi edit instead of direct editing**
   ```bash
   chezmoi edit ~/.bashrc  # Better than: nano ~/.bashrc
   ```

3. **Review changes before applying**
   ```bash
   chezmoi diff
   ```

4. **Commit frequently with descriptive messages**
   ```bash
   git commit -m "feat: add docker aliases to bash"
   ```

5. **Test in container before production**
   ```bash
   docker compose exec dotfiles bash
   ```

### DON'T ❌

1. **Don't edit managed files directly**
   ```bash
   # Bad
   nano ~/.bashrc
   
   # Good
   chezmoi edit ~/.bashrc
   ```

2. **Don't force push**
   ```bash
   # Bad
   git push --force
   
   # Good
   git pull --rebase && git push
   ```

3. **Don't forget to apply after pull**
   ```bash
   # Bad
   git pull  # Without chezmoi apply
   
   # Good
   git pull && chezmoi apply
   ```

---

## Quick Reference

```bash
# Setup
chezmoi init <repo>              # Initialize with repo
chezmoi apply                    # Apply dotfiles

# Daily usage
chezmoi edit ~/.bashrc           # Edit dotfile
chezmoi edit --apply ~/.bashrc   # Edit and apply
chezmoi add ~/.config/new        # Add new file
chezmoi diff                     # Show differences
chezmoi apply                    # Apply changes
chezmoi update                   # Pull and apply

# Git operations
cd ~/.local/share/chezmoi        # Go to source
git pull && chezmoi apply        # Sync from git
git add . && git commit && git push  # Push changes

# Container
docker compose exec dotfiles bash  # Enter container
# (changes in ~/Documents/all/github/dotfiles sync automatically via bind mount)

# Troubleshooting
chezmoi apply --force            # Force apply
chezmoi forget ~/.config/file    # Stop managing file
chezmoi data                     # Show variables
```

---

## Additional Resources

- [chezmoi Documentation](https://www.chezmoi.io/)
- [chezmoi Quick Start](https://www.chezmoi.io/quick-start/)
- [Template Syntax](https://www.chezmoi.io/user-guide/templating/)
- [Dotfiles Guide](../README.md)
- [FNOX Guide](./FNOX.md)

---

**Last Updated:** 2025-01-20  
**Author:** msavdert
