# Chezmoi — Dotfile Management Guide

Practical guide for managing dotfiles with [chezmoi](https://www.chezmoi.io/) in this repository.

## Key Concepts

| Term | Description |
|------|-------------|
| **Source directory** | `~/.local/share/chezmoi` — your dotfiles as templates/code |
| **Target directory** | `~` — your actual home directory |
| **Source state** | Desired state computed from source directory |
| **Target state** | Actual state of files on disk |

## Daily Workflow

### Edit → Preview → Apply

```bash
# 1. Edit a dotfile
chezmoi edit ~/.bashrc          # Opens in nvim
chezmoi edit --apply ~/.bashrc  # Edit + auto-apply on save

# 2. Preview changes
chezmoi diff                    # Show what would change
chezmoi status                  # Show modified/added files

# 3. Apply changes
chezmoi apply                   # Apply all changes
chezmoi apply -v                # Verbose apply
```

### Sync with Git

```bash
# Push local changes
chezmoi cd                      # cd into source directory
git add . && git commit -m "update dotfiles" && git push

# Or use chezmoi's git wrapper
chezmoi git add .
chezmoi git commit -m "update dotfiles"
chezmoi git push

# Pull remote changes
chezmoi update                  # git pull + apply in one command
```

### Add New Files

```bash
# Add an existing file to chezmoi management
chezmoi add ~/.config/newfile

# Add as a template (for machine-specific configs)
chezmoi add --template ~/.config/newfile

# Add a private file (600 permissions)
chezmoi add --encrypt ~/.ssh/id_rsa
```

## Templating

Templates use Go's `text/template` syntax. Any file ending in `.tmpl` is processed as a template.

### Template Variables

Variables are defined in `.chezmoi.toml.tmpl`:

```toml
[data]
    gitUser = "msavdert"
    gitEmail = "10913156+msavdert@users.noreply.github.com"
```

### Usage Examples

```bash
# In dot_gitconfig.tmpl
[user]
    name = {{ .gitUser }}
    email = {{ .gitEmail }}
```

```bash
# Machine-specific configuration
{{ if eq .chezmoi.hostname "work-laptop" }}
export WORK_SETTING="value"
{{ end }}

# OS-specific
{{ if eq .chezmoi.os "linux" }}
alias open='xdg-open'
{{ end }}
```

### Debugging Templates

```bash
chezmoi execute-template '{{ .chezmoi.hostname }}'
chezmoi execute-template '{{ .chezmoi.os }}/{{ .chezmoi.arch }}'
chezmoi data    # Show all available template data
```

## File Naming Convention

Chezmoi uses special prefixes to control file behavior:

| Prefix | Effect | Example |
|--------|--------|---------|
| `dot_` | Creates `.` prefix | `dot_bashrc` → `~/.bashrc` |
| `private_` | Sets `0600` permissions | `private_dot_ssh/` |
| `readonly_` | Sets read-only | `private_readonly_id_ed25519.age` |
| `executable_` | Sets `0755` permissions | `executable_script.sh` |
| `.tmpl` suffix | Process as template | `dot_gitconfig.tmpl` |
| `.age` suffix | Decrypt with age | `secret.age` |

## Container Workflow

### Quick Bootstrap

```bash
# One-shot mode (for ephemeral containers)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot msavdert

# Or use the full install script
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
```

### Development in Container

```bash
# Start the dev container
make shell

# Inside container, test dotfiles
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash

# Edit and push changes back
chezmoi edit ~/.bashrc
chezmoi cd && git add . && git commit -m "update" && git push
```

## Troubleshooting

### Common Issues

```bash
# "chezmoi: command not found"
mise install chezmoi        # Reinstall via mise

# Changes not applying
chezmoi diff               # Check what's different
chezmoi apply --force      # Force apply

# Template errors
chezmoi execute-template '{{ .chezmoi.hostname }}'  # Test template syntax
chezmoi doctor             # Run health check

# Corrupt source directory
chezmoi init --apply https://github.com/msavdert/dotfiles  # Reinitialize

# Nuclear option
chezmoi purge              # Remove all managed files
```

### Useful Commands Cheatsheet

```bash
chezmoi managed            # List all managed files
chezmoi unmanaged          # List unmanaged files in home
chezmoi doctor             # Health check
chezmoi cat ~/.bashrc      # Show what would be applied
chezmoi forget ~/.oldfile  # Stop managing a file
```

## Aliases

These aliases are defined in `dot_bash_aliases`:

| Alias | Command |
|-------|---------|
| `cm` | `chezmoi` |
| `cma` | `chezmoi apply` |
| `cdiff` | `chezmoi diff` |
| `cme` | `chezmoi edit` |
| `cmea` | `chezmoi edit --apply` |
| `cmu` | `chezmoi update` |
| `cms` | `chezmoi status` |
| `cmcd` | `chezmoi cd` |

## Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Template Functions Reference](https://www.chezmoi.io/reference/templates/functions/)
- [chezmoi GitHub](https://github.com/twpayne/chezmoi)

---

**Last Updated:** 2026-02-18