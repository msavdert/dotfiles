# dotfiles

A **thin macOS client** and a **containerised development environment**.

The laptop stays clean — a terminal, 1Password, and a short list of CLI tools, all
declared in a manifest that removes anything not on it. The real work happens
inside a container image with the whole toolchain baked in, running on a VPS,
one `ssh dev` away.

```
macOS (thin client)  ──ssh dev──▶  devbox container (VPS)
tabby · 1Password                  languages · nvim · zellij
orbstack · 11 mise CLIs            kubernetes · AI CLIs
macos/Brewfile                     ghcr.io/msavdert/devbox
```

## Quick start

**macOS**

```bash
git clone https://github.com/msavdert/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./macos/setup.sh
```

**VPS**

```bash
mkdir -p ~/devbox && cd ~/devbox
curl -fsSLO https://raw.githubusercontent.com/msavdert/dotfiles/main/compose.yaml
echo 'OP_SERVICE_ACCOUNT_TOKEN=ops_...' > .env && chmod 600 .env
docker compose up -d
```

**Connect** — add to `~/.ssh/config.local`:

```
Host dev
    HostName vps.example.com
    User melih
    RequestTTY yes
    RemoteCommand docker exec -it -u dev devbox zellij attach -c main
    ForwardAgent yes
```

Then `ssh dev` lands you in a persistent zellij session inside the container.

**Try it locally without a VPS**

```bash
docker run -it --rm ghcr.io/msavdert/devbox:latest zsh
```

## Layout

```
Dockerfile              devbox image — every tool installed at build time
compose.yaml            VPS deployment
macos/                  Brewfile + setup.sh (tier 0)
configs/
  mise/devbox.toml      container toolchain
  mise/macos.toml       host toolchain (4 tools)
  zsh/                  .zshenv, .zshrc, completion generator
  op/*.env              op:// references — no secret values
  nvim/ zellij/         devbox only
  git/ ssh/ starship.toml
.github/workflows/      multi-arch build → ghcr.io
docs/                   ← read this
```

## Documentation

Everything — what, why, and what was rejected — is in **[docs/](docs/README.md)**.

| | |
|---|---|
| [00 Architecture](docs/00-architecture.md) | the two tiers, and ten decision records |
| [01 macOS setup](docs/01-macos-setup.md) | keeping the laptop clean |
| [02 devbox image](docs/02-devbox-image.md) | what's inside, how it's built |
| [03 VPS deployment](docs/03-vps-deployment.md) | bare server → `ssh dev` |
| [04 Daily usage](docs/04-daily-usage.md) | the actual workflow |
| [05 Secrets](docs/05-secrets.md) | 1Password, plus Connect/Environments migrations |
| [06 Maintenance](docs/06-maintenance.md) | adding tools, upgrading, rolling back |
| [07 Troubleshooting](docs/07-troubleshooting.md) | symptom → cause → fix |

## Design in one paragraph

Tools are installed when the **image is built**, not when a container starts —
so start-up is seconds and every machine gets a byte-identical environment,
pinned by image digest. macOS packages are declared in a Brewfile applied with
`--cleanup`, so nothing can accumulate untracked. Secrets are never exported
into the shell; each command that needs one is wrapped in `op run`, which
resolves the `op://` references in `configs/op-env/*.env` in a single request and
injects them into that one process. Shell start-up does no work at all: no
network calls, no completion generation, no secret loading.

The reasoning behind each of those, and the alternatives that were considered
and rejected, is recorded in
[docs/00-architecture.md](docs/00-architecture.md#decision-records).

## License

MIT
