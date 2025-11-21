# dotfiles

My personal dotfiles managed with [mise](https://mise.jdx.dev/) + [chezmoi](https://www.chezmoi.io/) + [fnox](https://fnox.jdx.dev/).

**Repository:** `https://github.com/msavdert/dotfiles`

## Quick Start

Bootstrap a new machine with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
```

This will:
1. Install mise (tool version manager)
2. Install all required tools (chezmoi, fnox, age, starship, zellij, etc.)
3. Initialize chezmoi with your dotfiles
4. Set up fnox for secret management
5. Configure your shell

## What's Included

### Core Tools
- **mise** - Universal tool version manager
- **chezmoi** - Dotfile manager with templating support
- **fnox** - Secret management with age encryption
- **age** - Modern encryption tool

### Shell & Terminal
- **bash** - Default shell with custom configurations
- **starship** - Minimal, fast prompt
- **zellij** - Terminal multiplexer (modern tmux alternative)

### Cloud & Infrastructure
- **OCI CLI** - Oracle Cloud Infrastructure CLI
- **kubectl** - Kubernetes command-line tool
- **kubens** - Easy namespace switching
- **k9s** - Kubernetes TUI
- **helm** - Kubernetes package manager
- **terraform** - Infrastructure as Code
- **flux2** - GitOps for Kubernetes
- **kustomize** - Kubernetes configuration management

### Development Tools
- **neovim** - Modern Vim-based text editor
- **jq** - JSON processor
- **yq** - YAML/XML/JSON processor
- **usage** - CLI tool usage specifications

## Project Structure

```
dotfiles/
├── install.sh              # Bootstrap script (idempotent, minimal)
├── .chezmoiignore         # Files to exclude from home directory
├── .chezmoi.toml.tmpl     # Chezmoi config template
├── README.md              # This file
├── docs/
│   ├── FNOX.md            # Complete fnox usage guide
│   ├── CHEZMOI.md         # Complete chezmoi usage guide
│   └── DATABASE_MANAGEMENT.md  # Guide for database tools
├── dot_bashrc             # Bash configuration
├── dot_bash_aliases       # Bash aliases
├── dot_bash_profile       # Bash profile
├── dot_gitconfig          # Git configuration
├── dot_config/
│   ├── mise/
│   │   └── config.toml    # mise tool definitions (managed by chezmoi)
│   ├── fnox/
│   │   └── config.toml    # fnox encrypted secrets (managed by chezmoi)
│   ├── starship.toml      # Starship prompt config
│   └── zellij/
│       └── config.kdl     # Zellij terminal multiplexer config
├── private_dot_ssh/
│   ├── config.tmpl        # SSH client configuration
│   └── private_readonly_id_ed25519_github.age  # Encrypted SSH key
└── Dockerfile             # Test environment
```

## Usage

### Managing Tools with mise

```bash
# Install all defined tools
mise install

# Update all tools
mise upgrade

# Add a new tool globally
mise use -g <tool>@<version>

# List installed tools
mise list

# Show current versions
mise current
```

### Managing Dotfiles with chezmoi

```bash
# Edit a dotfile
chezmoi edit ~/.bashrc

# See what would change
chezmoi diff

# Apply changes
chezmoi apply

# Update dotfiles from git
chezmoi update

# Add a new file to dotfiles
chezmoi add ~/.config/newfile

# Quick edit and apply
chezmoi edit --apply ~/.bashrc
```

### Managing Secrets with fnox

```bash
# Initialize fnox (first time)
fnox init

# Set a secret (encrypted automatically)
fnox set API_KEY "your-secret-value"

# Get a secret
fnox get API_KEY

# List all secrets
fnox list

# Run command with secrets loaded
fnox exec -- ./deploy.sh

# Edit secrets directly
fnox edit
```

### Shell Aliases

Common aliases are defined in `.bash_aliases`:

```bash
# Navigation
..          # cd ..
...         # cd ../..

# File operations
ll          # ls -lAh with colors
la          # ls -A with colors

# Docker
d           # docker
dc          # docker compose
dps         # docker ps
dcup        # docker compose up -d
dcdown      # docker compose down

# Git
g           # git
gs          # git status
ga          # git add
gc          # git commit
gp          # git push
gl          # git log (pretty format)

# Kubernetes
k           # kubectl
kx          # kubectx
kn          # kubens

# Mise
m           # mise
mi          # mise install
mu          # mise use

# Chezmoi
cm          # chezmoi
cma         # chezmoi apply
cmd         # chezmoi diff
cme         # chezmoi edit
```

See the full list in `.bash_aliases` file.

## Secrets Management

Secrets are managed with fnox + age encryption:

1. **Age encryption**: Secrets are encrypted with your age key
2. **Safe to commit**: Encrypted secrets in `fnox.toml` can be committed to git
3. **Easy to use**: Simple CLI to manage secrets
4. **Flexible**: Support for multiple encryption providers (age, AWS KMS, etc.)

### Initial Setup

```bash
# Generate an age key (first time)
age-keygen -o ~/.config/fnox/key.txt

# Your public key will be shown - save it!
# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

# Initialize fnox with your public key
fnox init --provider age --recipient "age1ql3z..."
```

### Adding Secrets

```bash
# Database credentials
fnox set DB_HOST "db.example.com"
fnox set DB_USER "admin"
fnox set DB_PASSWORD "secret-password"

# API keys
fnox set AWS_ACCESS_KEY "AKIA..."
fnox set AWS_SECRET_KEY "secret..."

# SSH keys and certificates (multiline)
fnox set SSH_PRIVATE_KEY "$(cat ~/.ssh/id_rsa)"
```

## Customization

### Adding a New Tool

1. Add to `mise.toml`:
```toml
[tools]
my-tool = "latest"
```

2. Install:
```bash
mise install my-tool
```

### Adding a New Dotfile

```bash
# Add existing file to chezmoi
chezmoi add ~/.myconfig

# Edit in chezmoi
chezmoi edit ~/.myconfig

# Apply changes
chezmoi apply
```

### Machine-Specific Configuration

Use chezmoi templates for machine-specific configs:

```bash
# In your dotfile template (.bashrc.tmpl)
{{ if eq .chezmoi.hostname "work-laptop" }}
export WORK_SETTING="value"
{{ end }}
```

## Updating

Update everything:

```bash
# Update tools
mise upgrade

# Update dotfiles from git
chezmoi update

# Or do it all at once
mise upgrade && chezmoi update
```

## Testing

Test your dotfiles in a clean Docker environment:

```bash
# Build test container
docker compose build

# Run container
docker compose up -d

# Exec into container
docker compose exec dotfiles bash

# Test installation
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
```

## Troubleshooting

### mise not found
```bash
# Reinstall mise
curl https://mise.run | sh

# Activate mise
eval "$(~/.local/bin/mise activate bash)"
```

### chezmoi not applying changes
```bash
# Force apply
chezmoi apply --force

# Check diff first
chezmoi diff
```

### fnox can't decrypt
```bash
# Check age key exists
ls -la ~/.config/fnox/key.txt

# Verify key permissions
chmod 600 ~/.config/fnox/key.txt

# Test decryption
fnox list
```

## Contributing

1. Fork this repository
2. Make your changes
3. Test in Docker container
4. Submit a pull request

## Documentation

### Detailed Guides
- **[FNOX Guide](docs/FNOX.md)** - Complete guide for secret management with fnox + age
  - Backup & restore procedures
  - Zero-to-production setup
  - Key management and recovery
  - Security best practices
  
- **[CHEZMOI Guide](docs/CHEZMOI.md)** - Complete guide for dotfile management with chezmoi
  - Local changes workflow
  - Git synchronization
  - Container development workflow
  - Multi-machine synchronization
  
- **[Database Management Guide](docs/DATABASE_MANAGEMENT.md)** - Guide for DBA-specific tools and workflows

### External Resources

- [mise documentation](https://mise.jdx.dev/)
- [chezmoi documentation](https://www.chezmoi.io/)
- [fnox documentation](https://fnox.jdx.dev/)
- [starship documentation](https://starship.rs/)
- [zellij documentation](https://zellij.dev/)

## License

MIT License - Feel free to use this as a template for your own dotfiles!

## Author

**msavdert**
- GitHub: [@msavdert](https://github.com/msavdert)
- Email: 10913156+msavdert@users.noreply.github.com
