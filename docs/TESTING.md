# Testing Guide

How to test your dotfiles in isolated environments before applying to production machines.

## Quick Reference

| Method | Best For | Speed | Isolation |
|--------|----------|-------|-----------|
| **Docker** | Shell configs, aliases, tool installs | ⚡ Seconds | Kernel shared |
| **OrbStack** | SSH, systemd, full OS bootstrap | 🕐 Minutes | Full VM |

## Docker Testing

### Prerequisites

- Docker Desktop or OrbStack (Docker runtime)
- `docker compose` CLI

### Build & Enter

```bash
# Build the test container
make build

# Enter the container
make shell

# Or manually:
docker compose build
docker compose up -d
docker compose exec dotfiles bash
```

### Test the Install Script

```bash
# Full test: build + run install.sh in a clean container
make test

# Or manually:
docker compose run --rm dotfiles bash -c \
    "curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash"
```

### Iterative Development

```bash
# 1. Start container
make shell

# 2. Inside container — test install
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash

# 3. Make changes to dotfiles on host
# 4. Inside container — re-run install or apply specific changes
chezmoi update && source ~/.bashrc

# 5. When done
make clean    # Stop & remove everything
```

### What the Docker Container Includes

The `Dockerfile` provides:
- Ubuntu 24.04 base
- Essential packages: curl, git, python3, ripgrep, etc.
- Non-root user `msavdert` with sudo
- UTF-8 locale

The `docker-compose.yml` provides:
- Read-only mount of dotfiles at `/workspace`
- Persistent `mise-data` volume (tools survive rebuilds)
- Proper terminal settings (256 colors, timezone)

### Docker Limitations

- ❌ No systemd (can't test services)
- ❌ No real SSH server
- ❌ Shared kernel with host
- ❌ No GUI/desktop environment

## OrbStack Testing (macOS)

[OrbStack](https://orbstack.dev/) provides lightweight Linux VMs on macOS with full OS isolation.

### Create Test Machine

```bash
# Create a fresh Ubuntu machine
orb create ubuntu dotfiles-test

# Enter it
orb shell dotfiles-test

# Run the bootstrap script
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash

# Reload shell
source ~/.bashrc
```

### Test SSH Configuration

```bash
# OrbStack machines have real sshd
# From your Mac:
ssh dotfiles-test@orb

# Test SSH config was applied correctly
cat ~/.ssh/config
ssh -T git@github.com    # Test GitHub SSH key
```

### Test Full Bootstrap Flow

```bash
# Destroy and recreate for a clean test
orb delete dotfiles-test
orb create ubuntu dotfiles-test
orb shell dotfiles-test

# Simulate a real new machine setup:
# 1. Install dotfiles
curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash
source ~/.bashrc

# 2. Restore fnox key (from backup)
mkdir -p ~/.config/fnox && chmod 700 ~/.config/fnox
# Paste key content or copy from host

# 3. Verify everything works
mise list              # All tools installed?
chezmoi doctor         # Config healthy?
fnox list              # Can decrypt secrets?
starship --version     # Prompt working?
```

### OrbStack with Cloud-init

For automated provisioning testing:

```yaml
# cloud-init.yaml
#cloud-config
users:
  - name: msavdert
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

runcmd:
  - su - msavdert -c "curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash"
```

```bash
orb create ubuntu dotfiles-test --cloud-init cloud-init.yaml
```

## CI/CD Testing

The GitHub Actions workflow (`.github/workflows/docker.yml`) automatically:

1. **Lints** all shell scripts with [shellcheck](https://www.shellcheck.net/)
2. **Builds** the Docker image for `linux/amd64` and `linux/arm64`
3. **Pushes** to Docker Hub on `main` branch

### Run Lint Locally

```bash
# Install shellcheck (macOS)
brew install shellcheck

# Run
make lint

# Or directly:
shellcheck -s bash dot_bashrc dot_bash_aliases dot_bash_profile install.sh
```

## Troubleshooting

### Docker build fails

```bash
# Clean everything and rebuild
make clean
make build

# Check Docker daemon is running
docker info
```

### Mise tools fail to install in container

```bash
# Check if volume is mounted
docker compose exec dotfiles ls -la ~/.local/share/mise/

# Reset mise data volume
docker compose down -v
make build
```

### OrbStack machine won't start

```bash
orb list                    # Check status
orb delete dotfiles-test    # Remove and recreate
orb create ubuntu dotfiles-test
```

### install.sh fails

```bash
# Run with debug output
bash -x install.sh

# Check specific step
curl -fsSL https://mise.run | sh    # Test mise install separately
```

## Testing Checklist

When making changes, verify:

- [ ] `make lint` passes (shellcheck)
- [ ] `make build` succeeds
- [ ] `make test` — install.sh completes in clean container
- [ ] Shell opens without errors (`source ~/.bashrc`)
- [ ] All aliases work (`alias | wc -l`)
- [ ] Starship prompt renders correctly
- [ ] `chezmoi doctor` reports no issues
- [ ] Git config shows correct user/email (`git config user.name`)

---

**Last Updated:** 2026-02-18
