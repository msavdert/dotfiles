---
type: note
created: 2026-02-19
modified: 2026-02-19
tags:
  - tool
  - devops
  - macos
  - docker
  - virtualization
official_url: https://orbstack.dev
docs_url: https://docs.orbstack.dev
---

# OrbStack

OrbStack is a fast, lightweight, and simple way to run **Docker containers** and **Linux virtual machines** on macOS. It's a supercharged alternative to Docker Desktop, all in one native Swift app.

> [!TIP]
> OrbStack replaces Docker Desktop + Vagrant/UTM in a single tool. It starts in ~2 seconds, uses minimal CPU/battery, and provides seamless macOS integration.

## Requirements

- **macOS 13.0 (Ventura)** or newer
- Apple Silicon (M1/M2/M3/M4) or Intel Mac

## Installation

### GUI Installation (Recommended)

1. Download from [orbstack.dev/download](https://orbstack.dev/download)
2. Open the `.dmg` and drag to Applications
3. Launch OrbStack — it auto-installs CLI tools

### Homebrew

```bash
brew install orbstack
```

### What Gets Installed

OrbStack automatically installs CLI tools to `~/.orbstack/bin` and `/usr/local/bin`:

| Command | Description |
|---------|-------------|
| `orb` | Main CLI — manage machines, run commands |
| `orbctl` | Explicit machine management |
| `docker` | Docker CLI (latest version) |
| `docker compose` | Docker Compose v2 |
| `docker buildx` | Docker BuildKit |

> [!NOTE]
> If you already have Docker CLI from another source (Homebrew, Docker Desktop), OrbStack won't overwrite it. To switch, remove the old tools and restart OrbStack.

### Replacing Docker Desktop

OrbStack is a drop-in replacement:

```bash
# Check current Docker context
docker context ls

# OrbStack creates the "orbstack" context automatically
# It also creates a symlink at /var/run/docker.sock

# Migrate data from Docker Desktop (optional)
orb migrate docker
```

All `docker` and `docker compose` commands work identically.

### Uninstalling

```bash
# Remove the app from /Applications
# Then clean up data:
rm -rf ~/.orbstack
rm -rf ~/Library/Group\ Containers/HUAQ24HBR6.dev.orbstack

# If returning to Docker Desktop:
docker context use desktop-linux
```

---

## Docker Containers

OrbStack includes a full Docker engine. Everything you know about Docker works here — but faster.

### Basic Usage

```bash
# Run a container
docker run -it --rm ubuntu bash

# Docker Compose
docker compose up -d
docker compose logs -f

# Build images
docker build -t myapp .
docker build --platform linux/amd64 .    # Cross-arch build

# List containers
docker ps -a
```

### Intel (x86) Emulation on Apple Silicon

OrbStack uses **Rosetta** for fast x86 emulation:

```bash
# Run x86 container on M-series Mac
docker run -it --rm --platform linux/amd64 ubuntu bash

# Build for x86
docker build --platform linux/amd64 -t myapp:x86 .

# Set x86 as default (use with caution)
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```

### Zero-Config Domain Names

Every container gets an automatic domain — no port numbers needed!

| Type | Domain Format | Example |
|------|---------------|---------|
| Container | `container-name.orb.local` | `nginx.orb.local` |
| Compose | `service.project.orb.local` | `api.myapp.orb.local` |
| Machine | `machine-name.orb.local` | `devenv.orb.local` |

```bash
# Start a container
docker run -d --name myapp nginx

# Access via domain (from Mac browser)
curl http://myapp.orb.local
```

#### HTTPS Support

OrbStack provides zero-setup HTTPS with automatic certificate generation:

```bash
# Just change http:// to https://
curl https://myapp.orb.local
```

#### Custom Domains

```yaml
# docker-compose.yml
services:
  web:
    image: nginx
    labels:
      - dev.orbstack.domains=mysite.local,api.local
```

Wildcards: `dev.orbstack.domains=*.mysite.local`

> [!IMPORTANT]
> Custom domains only support the `.local` TLD.

### Networking

- Containers accessible at `localhost` (standard port forwarding)
- Domain-based access via `.orb.local` (see above)
- Full IPv6 support, ping, traceroute
- VPN compatibility — follows your macOS VPN/DNS settings
- Host networking supported

### Volumes & Mounts

```bash
# Bind mount (Mac → Container)
docker run -v $(pwd):/app myimage

# Named volume
docker volume create mydata
docker run -v mydata:/data myimage

# Access volume files from Mac via Finder
# OrbStack tab in Finder sidebar → Volumes
```

### SSH Agent Forwarding

Forward your SSH keys to containers (e.g., for Git):

```bash
docker run -it --rm \
  -v /run/host-services/ssh-auth.sock:/agent.sock \
  -e SSH_AUTH_SOCK=/agent.sock \
  ubuntu bash
```

### Engine Configuration

```bash
# Edit Docker daemon config
# OrbStack Settings → Docker → Advanced → Docker Engine
# Or edit: ~/.orbstack/config/docker/daemon.json
```

### Resource Usage

- Background CPU: ~0.1% on M-series
- Idle containers: near-zero overhead
- Stop unused containers to minimize resource usage

---

## Linux Machines (Virtual Machines)

OrbStack can create full Linux VMs — similar to WSL on Windows, but on macOS. These are lightweight, highly-integrated machines with real init systems.

### Supported Distributions (15)

| Distro | Default Version | Create Command |
|--------|----------------|----------------|
| **Ubuntu** | Latest LTS | `orb create ubuntu` |
| **Debian** | Stable | `orb create debian` |
| **Fedora** | Latest | `orb create fedora` |
| **Arch** | Rolling | `orb create arch` |
| **Alpine** | Latest | `orb create alpine` |
| **CentOS** | Stream | `orb create centos` |
| **Rocky** | Latest | `orb create rocky` |
| **Alma** | Latest | `orb create alma` |
| **Oracle** | Latest | `orb create oracle` |
| **openSUSE** | Leap | `orb create opensuse` |
| **Kali** | Rolling | `orb create kali` |
| **NixOS** | Stable | `orb create nixos` |
| **Gentoo** | Latest | `orb create gentoo` |
| **Devuan** | Latest | `orb create devuan` |
| **Void** | Latest | `orb create void` |

#### Specific Versions

```bash
orb create ubuntu:jammy           # Ubuntu 22.04 LTS
orb create ubuntu:noble           # Ubuntu 24.04 LTS
orb create debian:bookworm        # Debian 12
orb create fedora:39              # Fedora 39
orb create alma:8                 # Alma Linux 8
orb create alpine:edge            # Alpine Edge
orb create opensuse:tumbleweed    # openSUSE Tumbleweed
```

### Machine Management

```bash
# Create
orb create ubuntu devenv          # Create "devenv" Ubuntu machine

# List
orb list                          # List all machines

# Start / Stop
orb start devenv
orb stop devenv

# Restart
orb restart devenv

# Delete
orb delete devenv

# Rename
orb rename oldname newname

# Get info
orb info devenv

# Set default machine
orb default devenv
```

### Shell & Command Execution

```bash
# Open shell in default machine
orb

# Open shell in specific machine
orb -m devenv

# Open shell as specific user
orb -m devenv -u root

# Run a command
orb -m devenv uname -a
orb -m devenv cat /etc/os-release

# Run a script
orb -m devenv ./setup.sh
```

### Intel (x86) Machines on Apple Silicon

```bash
# Create an x86 machine (uses Rosetta emulation)
orb create --arch amd64 ubuntu devenv-x86

# Useful for testing x86-specific software
```

### Services & Init System

Linux machines have a **real init system** (systemd, OpenRC, or runit depending on distro):

```bash
# Inside an Ubuntu machine:
sudo apt install nginx
sudo systemctl start nginx
sudo systemctl enable nginx    # Start on boot

# The server is accessible from Mac at:
# - localhost (if port 80)
# - devenv.orb.local
```

### File Sharing

#### Mac → Linux

Mac files are available at `/mnt/mac` inside Linux machines:

```bash
# Inside Linux machine:
ls /mnt/mac/Users/$(whoami)/Documents
cat /mnt/mac/Users/$(whoami)/.bashrc
```

#### Linux → Mac

Linux files are accessible from Mac at `~/OrbStack/` or via Finder:

```bash
# On Mac:
ls ~/OrbStack/devenv/home/
open ~/OrbStack/devenv/    # Open in Finder
```

#### Between Machines

```bash
# From inside one machine, access another at /mnt/machines/
ls /mnt/machines/other-machine/home/
```

#### File Transfer Commands

```bash
# Mac → Linux
orb push ~/file.txt                          # Push to default machine
orb push -m devenv ~/file.txt /home/user/    # Push to specific machine/path

# Linux → Mac
orb pull ~/file.txt                          # Pull from default machine
orb pull -m devenv /home/user/file.txt       # Pull from specific machine
```

### SSH

OrbStack has a **built-in SSH server** — no need to install `openssh-server` in each machine.

```bash
# SSH from Mac to machine
ssh devenv@orb                     # Short form
ssh user@devenv.orb.local          # Domain form

# Get SSH details
orb ssh devenv

# SSH agent forwarding is automatic
# Your Mac SSH keys work inside machines without setup
```

> [!TIP]
> SSH agent is automatically forwarded. You can `git push` to GitHub from inside a machine using your Mac's SSH keys without copying them.

### Run Mac Commands from Linux

```bash
# Inside Linux machine:
mac uname -a                # Run uname on macOS
open file.txt               # Open file in macOS default app
ps | pbcopy                 # Copy to macOS clipboard
```

### User Accounts

```bash
# Default user: same username as macOS, with sudo access (no password)
sudo apt update              # Works without password

# Root access
orb -m devenv -u root

# Add additional users
sudo useradd -m newuser
```

### Networking

```bash
# Machine domain (from Mac)
curl http://devenv.orb.local

# Servers in Linux are accessible at localhost (same as Docker)
# If server listens on 0.0.0.0, also accessible from LAN

# Connect to Mac server from Linux
curl http://host.orb.internal

# Connect to Docker containers from Linux
curl http://docker.orb.internal

# Machine-to-machine (all on same network bridge)
# Up to 115 Gbps on M1 between machines
```

### Cloud-init

Automate machine setup using cloud-init (same format as AWS EC2):

```yaml
# cloud-init.yaml
#cloud-config
packages:
  - curl
  - git
  - build-essential

users:
  - name: msavdert
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

runcmd:
  - su - msavdert -c "curl -fsSL https://raw.githubusercontent.com/msavdert/dotfiles/main/install.sh | bash"
```

```bash
orb create ubuntu devenv --cloud-init cloud-init.yaml
```

### Automatic Setup (Script-based)

```bash
# Create + run setup script in one line
orb create ubuntu devenv && orb -m devenv ./setup.sh
```

### Resource Usage

- Idle machines use nearly **zero additional CPU** compared to OrbStack's baseline
- You can run **dozens of machines** simultaneously
- Memory is shared dynamically with macOS

### Environment Variables

```bash
# Pass environment variables
orb -m devenv -e MY_VAR=hello echo $MY_VAR
```

---

## Kubernetes

OrbStack includes a **lightweight single-node Kubernetes cluster** for development.

### Enable Kubernetes

1. OrbStack Settings → Kubernetes → Enable
2. Or: `orb k8s start`

### Usage

```bash
# kubectl works immediately
kubectl get pods
kubectl get nodes

# Images built with docker are immediately available
docker build -t myapp:dev .
# No need to push to registry — use in k8s directly
# Set imagePullPolicy: IfNotPresent for local images

# All service types accessible from Mac (no port-forward needed)
kubectl expose deployment myapp --type=LoadBalancer --port=80
# Access at: myapp.svc.orb.local
```

### Service Access

| Service Type | Access Method |
|-------------|---------------|
| LoadBalancer | `servicename.namespace.svc.orb.local` |
| NodePort | `localhost:nodeport` |
| ClusterIP | Direct IP routing from Mac |
| Pod IPs | Direct IP routing from Mac |

---

## CLI Reference

### `orb` — Main Command

```bash
# Machine management
orb create <distro> [name]       # Create machine
orb create --arch amd64 <distro> # Create x86 machine
orb list                         # List machines
orb delete <name>                # Delete machine
orb start [name]                 # Start machine/OrbStack
orb stop [name]                  # Stop machine/OrbStack
orb restart [name]               # Restart machine
orb rename <old> <new>           # Rename machine
orb default [name]               # Get/set default machine
orb info <name>                  # Machine info
orb logs <name>                  # Machine boot logs
orb status                       # OrbStack running status

# Shell & execution
orb                              # Shell in default machine
orb -m <name>                    # Shell in specific machine
orb -m <name> -u <user>          # Shell as specific user
orb -m <name> <command>          # Run command in machine
orb -m <name> -e KEY=VAL <cmd>   # Run with env var

# File operations
orb push <file> [dest]           # Mac → Linux
orb pull <file> [dest]           # Linux → Mac
orb push -m <name> <file> <dest> # To specific machine

# Docker/Kubernetes
orb docker ...                   # Docker commands
orb k8s ...                      # Kubernetes commands

# System
orb update                       # Update OrbStack
orb version                      # Show version
orb migrate docker               # Migrate from Docker Desktop
orb report                       # Generate bug report
orb reset                        # Delete all data
```

### `mac` — Run Mac Commands from Linux

```bash
mac <command>                    # Run command on macOS
mac open <file>                  # Open in macOS
mac notify "title" "message"     # macOS notification
mac push <file> [dest]           # Copy file to macOS
mac pull <file> [dest]           # Copy file from macOS
mac link <command>               # Create macOS command alias
mac unlink <command>             # Remove macOS command alias
```

---

## Fresh macOS Setup — Complete Guide

Setting up OrbStack on a brand new macOS for both Docker and Linux VM usage:

### Step 1: Install OrbStack

```bash
brew install orbstack
# Or download from https://orbstack.dev/download
```

Open OrbStack from Applications. It will start automatically and install CLI tools.

### Step 2: Verify Installation

```bash
# Check OrbStack is running
orb status

# Verify Docker works
docker run --rm hello-world

# Verify CLI tools
orb version
docker --version
docker compose version
```

### Step 3: Docker Setup

Docker is ready immediately. No additional configuration needed.

```bash
# Test Docker Compose
mkdir -p ~/test && cd ~/test
cat > docker-compose.yml << 'EOF'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
EOF

docker compose up -d
curl http://localhost:8080      # Should show nginx welcome page
curl http://web.test.orb.local  # Also works via domain!
docker compose down
```

### Step 4: Create a Linux Machine

```bash
# Create Ubuntu VM
orb create ubuntu devenv

# Enter it
orb -m devenv

# Inside: install common tools
sudo apt update && sudo apt install -y curl git build-essential

# Exit
exit
```

### Step 5: Verify Networking

```bash
# From Mac → Linux
curl http://devenv.orb.local    # If running a server

# SSH access
ssh devenv@orb

# File sharing
ls ~/OrbStack/devenv/
```

### Step 6: Configure OrbStack Settings

Open OrbStack app → Settings:

- **General**: Start at login ✅
- **Docker**: Engine config (daemon.json)
- **Kubernetes**: Enable if needed
- **Resources**: Auto-managed (recommended)

---

## Tips & Best Practices

### Performance

- OrbStack uses significantly less CPU and memory than Docker Desktop
- Idle machines use near-zero resources
- x86 emulation via Rosetta is much faster than QEMU

### Development Workflow

```bash
# Quick dev environment
orb create ubuntu dev && orb -m dev
# Inside: install your tools, test code

# Done? Delete it
orb delete dev
```

### Multiple Environments

```bash
orb create ubuntu web-dev
orb create ubuntu db-dev
orb create fedora test-env

# All run simultaneously with minimal resource impact
# Each has its own domain: web-dev.orb.local, db-dev.orb.local
```

### Docker + Linux Machine Together

```bash
# Run database in Docker
docker run -d --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=dev postgres

# Connect from Linux machine
orb -m devenv
psql -h docker.orb.internal -U postgres
```

---

## Troubleshooting

### OrbStack Won't Start

```bash
# Check status
orb status

# Try restarting
orb stop && orb start

# Reset (destructive — deletes all data)
orb reset
```

### Docker Commands Not Found

```bash
# Check if tools are installed
ls -la ~/.orbstack/bin/

# Manually add to PATH
export PATH="$HOME/.orbstack/bin:$PATH"
```

### Slow Performance

- Ensure macOS 13+ for Rosetta x86 emulation
- Stop unused containers: `docker stop $(docker ps -q)`
- Stop idle machines: `orb stop <name>`

### Network Issues

```bash
# Check VPN interference
# OrbStack follows macOS DNS/VPN settings

# Restart networking
orb restart
```

---

## Comparison

| Feature | OrbStack | Docker Desktop | UTM/Vagrant |
|---------|----------|----------------|-------------|
| Docker | ✅ | ✅ | ❌ |
| Linux VMs | ✅ | ❌ | ✅ |
| Kubernetes | ✅ | ✅ | ❌ |
| Startup | ~2 sec | ~15 sec | ~30 sec |
| Background CPU | ~0.1% | ~5% | Varies |
| Domain names | ✅ Auto | ❌ | ❌ |
| File sharing | ✅ Fast | 🟡 Slow | 🟡 Manual |
| SSH integration | ✅ Auto | ❌ | 🟡 Manual |
| GUI | ✅ Native Swift | ✅ Electron | ✅ Native |
| Price | Freemium | Freemium | Free/Varies |

---

## Resources

- [Official Website](https://orbstack.dev)
- [Documentation](https://docs.orbstack.dev)
- [Release Notes](https://docs.orbstack.dev/release-notes)
- [GitHub Issues](https://github.com/orbstack/orbstack/issues)
- [Discord Community](https://orbstack.dev/chat)
