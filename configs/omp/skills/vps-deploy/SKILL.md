---
name: vps-deploy
description: Use when deploying, updating, restarting, verifying or rolling back the devbox container on the VPS - the docker compose pull/up flow, what the work/state/kube volumes persist and what is deliberately disposable, the ssh dev entry path, health checks, and pinning an image digest to recover from a bad build.
---

# Deploying the devbox on the VPS

The VPS holds exactly two files: `compose.yaml` and `.env`, in `~/devbox`.
**This repo is never cloned onto the VPS** and no bootstrap script runs there -
everything else lives inside `ghcr.io/msavdert/devbox`. That is what makes the
server disposable.

Reference: `docs/03-vps-deployment.md`.

## Update an existing deployment

```bash
ssh vps
cd ~/devbox
docker compose pull && docker compose up -d
```

Containers are recreated; the three named volumes survive. Detach from zellij
first if you care about in-flight processes - the session layout persists in the
`state` volume, but running processes do not.

One-liner from the Mac:

```bash
ssh vps 'cd ~/devbox && docker compose pull && docker compose up -d'
```

## First-time deployment

```bash
mkdir -p ~/devbox && cd ~/devbox
curl -fsSLO https://raw.githubusercontent.com/msavdert/dotfiles/main/compose.yaml

cat > .env <<'EOF'
OP_SERVICE_ACCOUNT_TOKEN=ops_...
TZ=Europe/Istanbul
DEVBOX_MEMORY_LIMIT=8g
EOF
chmod 600 .env

docker compose pull
docker compose up -d
```

`OP_SERVICE_ACCOUNT_TOKEN` is the only secret handed to the container; create it
at 1Password -> Developer -> Service Accounts with read-only access to the
`dotfiles` vault (`skill://add-secret`). `compose.yaml` declares it with
`${OP_SERVICE_ACCOUNT_TOKEN:?...}`, so `docker compose up` fails loudly rather
than starting a container that cannot resolve any secret.

Docker itself and basic sshd hardening are covered in section 1 of
`docs/03-vps-deployment.md`.

## Persistence model

Three named volumes, nothing else:

| Volume | Mount | Holds |
|---|---|---|
| `work` | `/home/dev/work` | your code |
| `state` | `/home/dev/.local/state` | shell history, zellij sessions |
| `kube` | `/home/dev/.kube` | output of `mise run kube:homelab` |

**Everything outside these paths is disposable and is replaced on the next image
pull.** That is the point, not an oversight: `~/.zshrc`, `~/.config/nvim`,
`~/.config/op-env` and the whole toolchain come from the image, so an image
upgrade actually takes effect. Mounting `/home/dev` as one volume would shadow
all of it and silently freeze your configuration at first-boot state
(`CLAUDE.md` invariant 5).

Practical rules:

- Code goes in `~/work`.
- Anything else you want to keep must become a file in this repo so it arrives
  via the image - including OMP's declarative config (`skill://omp-tuning`) and
  the Neovim lockfile.
- OMP credentials in `~/.omp/agent/agent.db` are **not** persisted and are not
  baked into the image. Treat them like `gh` auth: re-authenticate after a
  rebuild.

## Entry path from the Mac

`~/.ssh/config.local` (never committed - it holds real hostnames, invariant 9):

```
Host dev
    HostName vps.example.com
    User melih
    RequestTTY yes
    RemoteCommand docker exec -it -u dev devbox zellij attach -c main
    ForwardAgent yes
    ServerAliveInterval 30

Host vps
    HostName vps.example.com
    User melih
```

- `ssh dev` lands inside the container, attached to a zellij session that
  survives disconnects. `-c` attaches if the session exists and creates it
  otherwise.
- `RequestTTY yes` is required: `RemoteCommand` does not allocate a TTY on its
  own and zellij needs one.
- `ssh vps` is the same host with no `RemoteCommand` - use it for anything that
  runs on the host, i.e. every `docker compose` command here.
- Second and subsequent connections are near-instant because `ControlMaster` in
  `configs/ssh/config` reuses the TCP connection.

## Verify

```bash
ssh vps 'cd ~/devbox && docker compose ps'   # State = running (restart: unless-stopped)
docker exec devbox op whoami                 # service account resolves
docker exec devbox mise ls                   # full toolchain present
docker exec devbox zsh -lc 'echo ok'         # shell starts clean
```

Then the real check:

```bash
ssh dev      # should land in zellij, inside the container
mise ls
op whoami
```

If something looks wrong:

```bash
docker compose logs --tail=100      # json-file driver, 10m x 3 files
docker inspect devbox --format '{{.Config.Image}} {{.Image}}'   # what is actually running
docker system df                    # reclaim with: docker system prune -a
```

There is no Docker healthcheck on this service; `CMD ["sleep", "infinity"]` with
`init: true` is the whole runtime contract. "Healthy" means the container is
running and `docker exec` reaches a working shell.

## Roll back

The image is the only thing that changes, so rollback is a pin. Find a good
digest:

```bash
docker buildx imagetools inspect ghcr.io/msavdert/devbox:latest
```

(or take it from the Actions run summary of any earlier build), then in
`compose.yaml` on the VPS:

```yaml
image: ghcr.io/msavdert/devbox@sha256:<known-good>
```

```bash
docker compose up -d
```

The three volumes are untouched, so no work is lost. Tags also work:
`:20260730` for a specific day, `:sha-<commit>` for a specific commit - useful
for bisecting a regression that appeared sometime last month. Only
`@sha256:...` is truly immutable.

Remember to remove the pin once the fix ships, otherwise the VPS stops tracking
`latest` and quietly stays behind forever.

## Backups

The image needs no backup - it is rebuildable from this repo. Only `work` holds
anything irreplaceable, and most of that should be pushed to git anyway.

```bash
docker run --rm -v devbox_work:/data -v "$PWD:/backup" ubuntu \
  tar czf /backup/work-$(date +%F).tar.gz -C /data .
```
