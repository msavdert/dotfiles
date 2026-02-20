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

> **Important:** After install, restore your age key for secret access. See [fnox guide](docs/FNOX.md#restore-on-new-machine).

## What's Included

### Core Tools
- **mise** — Universal tool version manager
- **chezmoi** — Dotfile manager with templating support
- **fnox** — Secret management with age encryption
- **age** — Modern encryption tool

### Shell & Terminal
- **bash** — Default shell with custom configurations
- **starship** — Minimal, fast prompt
- **zellij** — Terminal multiplexer (modern tmux alternative)

### Cloud & Infrastructure
- **OCI CLI** — Oracle Cloud Infrastructure CLI
- **kubectl** — Kubernetes command-line tool
- **k9s** — Kubernetes TUI
- **helm** — Kubernetes package manager
- **terraform** — Infrastructure as Code
- **flux2** — GitOps for Kubernetes
- **kustomize** — Kubernetes configuration management
- **cilium-cli** — Cilium CNI management

### Development Tools
- **neovim** — Modern Vim-based text editor
- **jq / yq** — JSON & YAML processors
- **ripgrep** — Fast search tool
- **github-cli** — GitHub from the terminal

## Project Structure

```
dotfiles/
├── install.sh                 # Bootstrap script (idempotent)
├── Makefile                   # Dev workflow commands
├── .chezmoi.toml.tmpl         # Chezmoi config template
├── .chezmoiignore             # Files excluded from home directory
├── dot_bashrc                 # Bash configuration
├── dot_bash_aliases           # Bash aliases
├── dot_bash_profile           # Bash profile (login shell)
├── dot_gitconfig.tmpl         # Git configuration (templated)
├── dot_config/
│   ├── mise/config.toml       # mise tool definitions
│   ├── starship.toml          # Starship prompt config
│   └── zellij/config.kdl      # Zellij multiplexer config
├── private_dot_ssh/
│   ├── config.tmpl            # SSH client configuration
│   └── *.age                  # Encrypted SSH keys
├── fnox.toml                  # Encrypted secrets (safe in git)
├── Dockerfile                 # Test environment
├── docker-compose.yml         # Docker dev environment
├── .github/workflows/
│   └── docker.yml             # CI: shellcheck + Docker build
└── docs/
    ├── CHEZMOI.md             # Chezmoi usage guide
    ├── FNOX.md                # Secret management guide
    ├── DATABASE_MANAGEMENT.md # DBA tools & workflows
    └── TESTING.md             # Testing guide (Docker & OrbStack)
```

## Usage

### Managing Dotfiles

```bash
chezmoi edit ~/.bashrc          # Edit a dotfile
chezmoi diff                    # Preview changes
chezmoi apply                   # Apply changes
chezmoi update                  # Pull from git + apply
```

### Managing Tools

```bash
mise install                    # Install all defined tools
mise upgrade                    # Update all tools
mise use -g <tool>@<version>    # Add a new global tool
mise list                       # List installed tools
```

### Managing Secrets

```bash
fnox set API_KEY "secret"       # Store a secret (encrypted)
fnox get API_KEY                # Retrieve a secret
fnox list                       # List all secrets
fnox exec -- ./deploy.sh        # Run command with secrets loaded
```

### Shell Aliases

Common aliases defined in `.bash_aliases`:

| Category | Aliases |
|----------|---------|
| **Navigation** | `..` `...` `....` |
| **Files** | `ll` `la` `lt` |
| **Docker** | `d` `dc` `dps` `dcup` `dcdown` |
| **Git** | `g` `gs` `ga` `gc` `gp` `gl` |
| **Kubernetes** | `k` `kn` `kgp` `kgs` `kga` |
| **Terraform** | `tf` `tfi` `tfp` `tfa` |
| **Chezmoi** | `cm` `cma` `cdiff` `cme` `cmu` |
| **Mise** | `m` `mi` `mu` `ml` |
| **Fnox** | `fe` `fg` `fs` `fl` `fx` |

See full list: `dot_bash_aliases`

## Development & Testing

```bash
make help     # Show available commands
make build    # Build Docker test environment
make shell    # Enter test container
make test     # Build + run install.sh in clean container
make lint     # Run shellcheck on all scripts
make clean    # Stop containers, remove volumes
```

See [Testing Guide](docs/TESTING.md) for detailed instructions on Docker and OrbStack testing.

## Documentation

| Guide | Description |
|-------|-------------|
| [BOOTSTRAP.md](docs/BOOTSTRAP.md) | **Start here** — Full setup guide with fnox examples |
| [CHEZMOI.md](docs/CHEZMOI.md) | Dotfile management with chezmoi |
| [FNOX.md](docs/FNOX.md) | Secret management with fnox + age |
| [DATABASE_MANAGEMENT.md](docs/DATABASE_MANAGEMENT.md) | DBA tools & workflows |
| [TESTING.md](docs/TESTING.md) | Testing with Docker & OrbStack |
| [ORBSTACK.md](docs/ORBSTACK.md) | OrbStack reference guide |

### External Resources

- [mise documentation](https://mise.jdx.dev/)
- [chezmoi documentation](https://www.chezmoi.io/)
- [fnox documentation](https://fnox.jdx.dev/)
- [starship documentation](https://starship.rs/)
- [zellij documentation](https://zellij.dev/)

## License

MIT License — Feel free to use this as a template for your own dotfiles!

## Author

**msavdert**
- GitHub: [@msavdert](https://github.com/msavdert)
- Email: 10913156+msavdert@users.noreply.github.com
