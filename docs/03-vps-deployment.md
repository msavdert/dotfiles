# 03 — VPS deployment

Bare Ubuntu VPS → `ssh dev` drops you into a working environment. About ten
minutes, most of it the image pull.

## 1. Prepare the VPS

As a normal user with sudo (never work as root):

```bash
# Docker, official repo
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
newgrp docker    # or log out and back in

# Basic hardening: no password logins, no root logins
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/'                /etc/ssh/sshd_config
sudo systemctl restart ssh
```

Make sure your public key is in `~/.ssh/authorized_keys` **before** disabling
password auth, or you'll lock yourself out. With the 1Password SSH agent on the
Mac, get it with `op item get "<your key>" --fields "public key"`.

## 2. Deploy

```bash
mkdir -p ~/devbox && cd ~/devbox
curl -fsSLO https://raw.githubusercontent.com/msavdert/dotfiles/main/compose.yaml

cat > .env <<'EOF'
OP_SERVICE_ACCOUNT_TOKEN=ops_...
TZ=Europe/Istanbul
DEVBOX_MEMORY_LIMIT=8g
EOF
chmod 600 .env

# ghcr packages are public by default for public repos; if yours is private:
#   echo "$GH_PAT" | docker login ghcr.io -u msavdert --password-stdin

docker compose pull
docker compose up -d
```

Note that the VPS only ever needs `compose.yaml` and `.env`. **This repo is
never cloned onto the VPS** — everything else is inside the image. That's what
makes the server disposable.

Getting the service account token: 1Password → Developer → Service Accounts →
create one with read access to the `dotfiles` vault. See
[05-secrets.md](05-secrets.md).

## 3. Connect from the Mac

Add to `~/.ssh/config.local` (not committed — it holds real hostnames):

```
Host dev
    HostName vps.example.com
    User melih
    RequestTTY yes
    RemoteCommand docker exec -it -u dev devbox zellij attach -c main
    ForwardAgent yes
    ServerAliveInterval 30
```

Now `ssh dev` lands you inside the container, attached to a zellij session that
survives disconnects. Second and subsequent connections are near-instant because
`ControlMaster` (in `configs/ssh/config`) reuses the TCP connection.

Line by line:

- **`RequestTTY yes`** — `RemoteCommand` doesn't allocate a TTY on its own, and
  zellij needs one.
- **`RemoteCommand`** — runs on the VPS host, entering the container. `-c` means
  "attach if the session exists, create it otherwise".
- **`ForwardAgent yes`** — per-host, because the global default is `no` (see
  [D9](00-architecture.md#d9--ssh-agent-forwarding-is-off-by-default)). Only
  useful together with the socket mount described below.

To get a plain VPS shell without entering the container, add a second block
pointing at the same host with no `RemoteCommand`:

```
Host vps
    HostName vps.example.com
    User melih
```

## 4. Verify

```bash
ssh dev            # should land in zellij, inside the container
mise ls            # the full toolchain
op whoami          # service account resolves
```

## Persistence model

Three named volumes, nothing else:

| Volume | Mount | Holds |
|---|---|---|
| `work` | `/home/dev/work` | your code |
| `state` | `/home/dev/.local/state` | shell history, zellij sessions |
| `kube` | `/home/dev/.kube` | output of `mise run kube:homelab` |
| `omp` | `/home/dev/.omp/agent` | OMP agent state, auth database & session transcripts |
| `claude_auth` | `/home/dev/.claude` | Claude Code settings, auth & history |
| `agy_auth` | `/home/dev/.gemini` | Antigravity (AGY) CLI auth & state |

**Everything outside these paths is disposable and will be replaced on the next
image pull.** That's deliberate — see
[D6](00-architecture.md#d6--the-home-directory-is-not-one-big-volume). If a
`/home/dev` volume were mounted instead, pulling a new image with an updated
`.zshrc` would change nothing, because the volume would shadow it.

Practical rule: **code goes in `~/work`.** Anything you want to keep that isn't
code should become a config file in this repo, so it arrives via the image.

## Updating

```bash
ssh vps
cd ~/devbox
docker compose pull && docker compose up -d
```

Containers are recreated; the three volumes survive. Detach from zellij first if
you care about in-flight processes — the session state persists but running
processes do not.

## Rolling back

```yaml
# compose.yaml
image: ghcr.io/msavdert/devbox@sha256:<digest that worked>
```

```bash
docker compose up -d
```

Find previous digests with
`docker buildx imagetools inspect ghcr.io/msavdert/devbox:latest`, or from the
Actions run summary of any earlier build.

## Backups

The image needs no backing up — it's rebuildable from this repo. Only the `work`
volume holds anything irreplaceable, and most of it should be pushed to git
anyway.

```bash
# ad-hoc snapshot of the work volume
docker run --rm -v devbox_work:/data -v "$PWD:/backup" ubuntu \
  tar czf /backup/work-$(date +%F).tar.gz -C /data .
```

## Later: Tailscale

The recommended upgrade once the basics are boring. Add Tailscale to the
container, `tailscale up --ssh`, and then:

- No SSH port exposed on the VPS at all — close 22 to the internet.
- `ssh dev@devbox` works from any of your devices by name, no `HostName`, no
  `RemoteCommand`, no `docker exec` indirection.
- Agent forwarding lands *inside* the container natively, which removes the
  socket-mounting workaround in [05-secrets.md](05-secrets.md).
- Access control moves to Tailscale ACLs and device identity instead of
  `authorized_keys`.

Deliberately not done yet: the setup above needs no new infrastructure and works
today. Do this when you get tired of `RemoteCommand`, or the moment you want to
reach the devbox from a second device.
