# Working with Chezmoi: Container and GitHub Dotfiles Management

This guide provides comprehensive instructions for using Chezmoi to manage your dotfiles, with a focus on container environments and GitHub repository synchronization. Based on the official Chezmoi documentation (FAQ Usage and Daily Operations), this covers all daily workflows and scenarios.

## Table of Contents
- [Overview](#overview)
- [Initial Setup](#initial-setup)
- [Daily Operations](#daily-operations)
- [Container-Specific Workflows](#container-specific-workflows)
- [GitHub Repository Management](#github-repository-management)
- [Advanced Scenarios](#advanced-scenarios)
- [Troubleshooting](#troubleshooting)

## Overview

Chezmoi is a dotfile manager that treats your dotfiles as code, stored in a Git repository. It supports templating, encryption, and cross-machine synchronization. In container environments, it enables consistent development setups.

Key concepts:
- **Source directory**: Where your dotfiles are stored as templates/code
- **Target directory**: Your home directory where files are applied
- **Source state**: The desired state computed from source directory
- **Target state**: The actual state of files in target directory

## Initial Setup

### Installing Chezmoi
```bash
# Via install script (recommended)
sh -c "$(curl -fsLS get.chezmoi.io)"

# Via package manager
# macOS: brew install chezmoi
# Ubuntu: sudo apt install chezmoi
# Or via mise: mise use chezmoi@latest
```

### Initializing with Your Dotfiles Repo
```bash
# Initialize with GitHub repo
chezmoi init https://github.com/msavdert/dotfiles

# Apply dotfiles to home directory
chezmoi apply

# Or do both in one command
chezmoi init --apply https://github.com/msavdert/dotfiles
```

### Container Setup
For containers (like Docker), use the one-shot mode to avoid leaving traces:
```bash
# Install and apply dotfiles, then clean up
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot msavdert
```

## Daily Operations

### Editing Dotfiles

#### Method 1: Using chezmoi edit (Recommended)
```bash
# Edit a dotfile (opens in your configured editor)
chezmoi edit ~/.bashrc

# Edit and automatically apply changes when you quit
chezmoi edit --apply ~/.bashrc

# Edit with live apply on save (requires editor support)
chezmoi edit --watch ~/.bashrc
```

#### Method 2: Direct Source Directory Editing
```bash
# Open shell in source directory
chezmoi cd

# Edit files directly, then check changes
git status
chezmoi diff

# Apply changes
chezmoi apply
```

#### Method 3: Manual Home Directory Editing
```bash
# Edit file in home directory
vim ~/.bashrc

# Then either re-add or merge
chezmoi re-add ~/.bashrc
# OR
chezmoi merge ~/.bashrc
```

### Checking Status and Differences

```bash
# See what files are managed
chezmoi managed

# See what files are not managed
chezmoi unmanaged

# See differences between source and target
chezmoi diff

# See status (modified, added, etc.)
chezmoi status
```

### Applying Changes

```bash
# Apply all changes
chezmoi apply

# Apply specific file
chezmoi apply ~/.bashrc

# Apply with verbose output
chezmoi apply -v
```

### Committing Changes to Git

#### Manual Commit
```bash
# Open shell in source directory
chezmoi cd

# Standard git workflow
git add .
git commit -m "Update dotfiles"
git push
```

#### Using chezmoi git Command
```bash
# Run git commands in source directory
chezmoi git add .
chezmoi git commit -m "Update dotfiles"
chezmoi git push
```

#### Auto-commit Setup
Add to `~/.config/chezmoi/chezmoi.toml`:
```toml
[git]
    autoCommit = true
    autoPush = true
```

### Pulling and Updating

```bash
# Pull latest changes and apply
chezmoi update

# Pull and see diff without applying
chezmoi git pull --autostash --rebase && chezmoi diff

# Then apply if satisfied
chezmoi apply
```

## Container-Specific Workflows

### Development Container Setup

1. **Base Dockerfile** (from your repo):
```dockerfile
FROM ubuntu:24.04

# Install chezmoi and dependencies
RUN apt-get update && apt-get install -y curl git && \
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create user
RUN useradd -ms /bin/bash devuser
USER devuser
WORKDIR /home/devuser

# Set up dotfiles
RUN chezmoi init --apply https://github.com/msavdert/dotfiles

CMD ["/bin/bash"]
```

2. **Building and Running**:
```bash
docker build -t dev-env .
docker run -it dev-env
```

### Container Development Workflow

```bash
# In container, edit dotfiles
chezmoi edit ~/.bashrc

# Test changes
source ~/.bashrc

# Commit changes back to repo
chezmoi cd
git add .
git commit -m "Update bashrc for container dev"
git push
```

### Ephemeral Containers

For short-lived containers, use one-shot mode:
```bash
docker run --rm -it ubuntu:24.04 bash -c '
  apt-get update && apt-get install -y curl git &&
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot msavdert
'
```

## GitHub Repository Management

### Repository Structure

Your dotfiles repo should follow this structure:
```
dotfiles/
├── .chezmoiignore          # Files to ignore
├── .chezmoidata/           # Template data
├── .chezmoiscripts/        # Scripts to run
├── .chezmoitemplates/      # Custom templates
├── dot_bashrc              # Source for ~/.bashrc
├── dot_gitconfig           # Source for ~/.gitconfig
├── private_dot_ssh/        # Private SSH keys
└── docs/                   # Documentation
```

### Managing Private Files

#### Using chezmoi ignore
Create `.chezmoiignore`:
```
# Private keys
private_dot_ssh/

# OS-specific files
**/*.darwin
**/*.linux
```

#### Using Encryption
For sensitive files, use chezmoi's encryption:
```bash
# Encrypt a file
chezmoi encrypt ~/.ssh/id_rsa

# Decrypt when needed
chezmoi decrypt ~/.ssh/id_rsa
```

### Branching Strategy

```bash
# Create feature branch for changes
chezmoi cd
git checkout -b feature/add-new-tool

# Make changes
chezmoi edit ~/.config/newtool

# Test and commit
chezmoi apply
git add .
git commit -m "Add new tool configuration"

# Merge back
git checkout main
git merge feature/add-new-tool
git push
```

### Handling Conflicts

```bash
# When pulling causes conflicts
chezmoi update  # This will show conflicts

# Resolve in source directory
chezmoi cd
git status
# Edit conflicting files
git add .
git commit

# Apply resolved changes
chezmoi apply
```

## Advanced Scenarios

### Machine-Specific Configurations

#### Using Templates
Create `dot_bashrc.tmpl`:
```bash
# Common bash config
export PATH="$HOME/bin:$PATH"

# Machine-specific
{{ if eq .chezmoi.hostname "work-laptop" }}
export WORK_CONFIG="enabled"
{{ else if eq .chezmoi.hostname "home-desktop" }}
export HOME_CONFIG="enabled"
{{ end }}
```

#### Using .chezmoidata
Create `.chezmoidata/machine.yaml`:
```yaml
work-laptop:
  work_config: true
home-desktop:
  home_config: true
```

### External File Management

#### Git Repositories as Externals
For managing external git repos (like vim plugins):
```bash
# Add external git repo
chezmoi add --external git-repo https://github.com/user/plugin ~/.vim/pack/plugin/start/plugin
```

#### Regular File Externals
For downloading files:
```bash
chezmoi add --external https://example.com/file.txt ~/.config/file.txt
```

### Scripts and Hooks

#### Run Scripts on Changes
Create `.chezmoiscripts/run_onchange_after_bashrc.sh`:
```bash
#!/bin/bash
echo "Bashrc updated, reloading..."
source ~/.bashrc
```

#### Pre/Post Apply Hooks
In `chezmoi.toml`:
```toml
[hooks]
    preApply = ["echo 'Applying dotfiles...'"]
    postApply = ["echo 'Dotfiles applied successfully'"]
```

### Password Manager Integration

Chezmoi supports various password managers for secrets in templates.

#### Example with Bitwarden
```bash
# Install rbw (Bitwarden CLI)
chezmoi add --script run_once_install-rbw.sh << 'EOF'
#!/bin/bash
cargo install rbw
EOF

# Use in templates
# {{ (bitwarden "item-name").password }}
```

## Troubleshooting

### Common Issues

#### "chezmoi: command not found"
```bash
# Reinstall
sh -c "$(curl -fsLS get.chezmoi.io)"

# Or via mise
mise use chezmoi@latest
```

#### Changes not applying
```bash
# Check diff
chezmoi diff

# Force apply
chezmoi apply --force
```

#### Permission issues
```bash
# Check file permissions
ls -la ~/.config/chezmoi/

# Fix permissions
chmod 755 ~/.config/chezmoi/
```

#### Template errors
```bash
# Debug template
chezmoi execute-template '{{ .chezmoi.hostname }}'

# Check template data
chezmoi data
```

### Container-Specific Issues

#### No editor in container
```bash
# Set editor to a simple one
export EDITOR=nano

# Or install vim
apt-get install -y vim
```

#### Network issues in container
```bash
# For GitHub access
chezmoi init --apply --source https://github.com/msavdert/dotfiles
```

### Recovery

#### If source directory is corrupted
```bash
# Reinitialize
chezmoi init https://github.com/msavdert/dotfiles

# Or restore from backup
chezmoi state reset
```

#### Emergency cleanup
```bash
# Remove all chezmoi-managed files
chezmoi purge

# Remove chezmoi completely
rm -rf ~/.config/chezmoi ~/.local/share/chezmoi
```

## Best Practices

1. **Commit Frequently**: Use auto-commit for small changes
2. **Test in Container**: Always test dotfile changes in a clean container
3. **Use Templates**: For machine-specific configurations
4. **Encrypt Secrets**: Use chezmoi's encryption for sensitive files
5. **Document Changes**: Keep docs/ updated with your workflows
6. **Branch for Changes**: Don't commit directly to main
7. **Regular Updates**: Keep chezmoi and your dotfiles updated

## Resources

- [Official Chezmoi Documentation](https://www.chezmoi.io/)
- [Chezmoi GitHub](https://github.com/twpayne/chezmoi)
- [Community Examples](https://github.com/topics/chezmoi)
- [Template Functions Reference](https://www.chezmoi.io/reference/templates/functions/)

This guide covers all essential workflows for managing dotfiles with Chezmoi in both local and container environments. Start with the basic operations and gradually adopt advanced features as needed.</content>
<parameter name="filePath">/Users/melihsavdert/Documents/all/github/dotfiles/docs/CHEZMOI.md