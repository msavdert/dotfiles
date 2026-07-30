# 05 — Secrets & 1Password

## The rule

**No secret is ever exported into the shell environment.** Commands that need
secrets are wrapped; the values live in one process and die with it.

## How it works

`configs/op-env/*.env` files contain only `op://` references — no secret values —
which is why they're safe to commit:

```ini
# configs/op-env/ai.env
ANTHROPIC_BASE_URL=https://openrouter.ai/api
ANTHROPIC_AUTH_TOKEN=op://dotfiles/OpenRouter/generaltoken
ANTHROPIC_MODEL=moonshotai/kimi-k2.6
OPENROUTER_API_KEY=op://dotfiles/OpenRouter/generaltoken
GEMINI_API_KEY=op://dotfiles/Google/gemini-cli-token
```

> **Why `~/.config/op-env` and not `~/.config/op`.** `~/.config/op` is the
> 1Password CLI's *own* state directory — it holds `config` and
> `op-daemon.sock`. Symlinking our files over it breaks `op` entirely. The
> obvious name is taken; use the boring one.

`op run` resolves every reference in **one** request and injects the results
into the child process only:

```bash
opwith ai claude      # → op run --env-file=~/.config/op-env/ai.env -- claude
```

`.zshrc` defines thin wrappers so this is invisible day to day:

```zsh
claude()   { opwith ai claude "$@"; }
kilocode() { opwith ai kilocode "$@"; }
```

These can't recurse: `op run` execs the binary directly via PATH lookup, without
going through a shell, so the zsh function never applies to the child.

## Why not just export them at login

The previous setup sourced `personal.env` from `.zshrc`, which ran four
sequential `op read` calls. Two problems:

**Latency.** Four network round-trips before you get a prompt, on *every* new
terminal — every zellij pane, every `ssh dev`, every `exec zsh`. `op run` makes
one request, and only when you actually run the command.

**Blast radius.** An exported variable is inherited by every child process and
readable from `/proc/<pid>/environ`. Any `npm install` postinstall script, any
dependency, any crash reporter running in that shell can see your tokens. With
injection, only the one process that needs the secret ever sees it.

There's a third, quieter benefit: the wrapper is self-documenting. A year from
now, `configs/op-env/ai.env` tells you exactly which secrets `claude` needs.

### `--no-masking`

The wrapper passes `--no-masking`. By default `op run` scans the child's output
and replaces anything matching a secret with `<concealed>`. That's a good safety
net for scripts and a bad idea for interactive TUIs, where it corrupts redraws
and can mangle long outputs. Since these commands are interactive, masking is
off. For a CI-style script, drop the flag.

## Authentication

**On the devbox:** a **service account** token in `OP_SERVICE_ACCOUNT_TOKEN`,
supplied through `.env` next to `compose.yaml`. Create one at
1Password → Developer → Service Accounts, with read-only access to the
`dotfiles` vault and nothing else.

This is the single secret that has to exist as plaintext somewhere, and it's the
one to rotate if the VPS is ever compromised. Rotating it invalidates
everything: create a new one, update `.env`, `docker compose up -d`.

**On the Mac:** the 1Password desktop app. `op` talks to it over the local
socket and unlocks with Touch ID — no token on disk at all. Run `op signin` once
per session if prompted.

## SSH keys

Keys live in 1Password and are served by its SSH agent
(`configs/ssh/config.macos`). No private key file exists on the Mac.

### Outbound SSH from the devbox

If you need to `ssh` from inside the container to somewhere else, the agent has
to reach in. Two options:

**Now — mount the forwarded socket.** `ssh dev` forwards the agent to the VPS
host, where sshd puts the socket at a random path under `/tmp`. Pin it to a
stable location by adding this to the VPS user's `~/.zshrc` / `~/.bashrc`:

```bash
if [ -n "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" ]; then
    ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
fi
```

then uncomment in `compose.yaml`:

```yaml
    environment:
      SSH_AUTH_SOCK: /ssh-agent
    volumes:
      - /home/melih/.ssh/agent.sock:/ssh-agent
```

Fiddly, and it only works while an ssh session is live.

**Later — Tailscale SSH.** Connect to the container directly and agent
forwarding lands inside it natively, with none of the above. This is the main
practical reason to eventually adopt Tailscale
([03-vps-deployment.md](03-vps-deployment.md#later-tailscale)).

**Note that git needs none of this.** `~/.gitconfig` uses
`gh auth git-credential` over HTTPS, so the devbox pushes and pulls without any
SSH key.

## Adding a new secret

1. Store it in the `dotfiles` vault in 1Password.
2. Add a reference line to the appropriate `configs/op-env/*.env` (or create a new
   one — `opwith <name>` picks up any file in `~/.config/op-env/`).
3. Wrap the command in `.zshrc`, or call `opwith <name> <command>` directly.
4. Commit. **Verify you committed a reference, not a value** — `op://` prefix,
   always.

## Auditing

```bash
env | grep -iE 'token|key|secret'    # should print nothing
git log -p -- configs/op-env/ | grep -E 'sk-|ghp_|github_pat_'   # should print nothing
```

The second one is worth running occasionally. This repo's history is clean — it
was checked during the rewrite — but a single careless commit changes that
permanently, and rewriting published git history is far more painful than
rotating a token.

If a secret does get committed: **rotate it first**, then worry about history.
A rotated secret in a public commit is harmless; a scrubbed history containing a
live secret is not, because clones and forks keep the old objects.

---

# Future: 1Password Connect

**What it solves:** every `op read` / `op run` currently makes a round-trip to
1Password's servers. Connect is a self-hosted sync server that keeps an
encrypted copy of the vault locally, turning those into localhost calls —
milliseconds instead of hundreds of them.

**When it's worth it:** when you're resolving secrets often enough that the
latency is annoying, or when you want the devbox to keep working while
1Password's API is unreachable.

**Not worth it now** at current usage — it's two more containers to run, update
and monitor, to save a few hundred milliseconds on commands you run a handful of
times a day.

**Migration, when the time comes:**

1. 1Password → Developer → Connect → create a server, download
   `1password-credentials.json` and an access token.
2. Add to `compose.yaml`:
   ```yaml
     onepassword-connect:
       image: 1password/connect-api:latest
       restart: unless-stopped
       volumes:
         - ./1password-credentials.json:/home/opuser/.op/1password-credentials.json:ro
         - connect-data:/home/opuser/.op/data
     onepassword-sync:
       image: 1password/connect-sync:latest
       restart: unless-stopped
       volumes:
         - ./1password-credentials.json:/home/opuser/.op/1password-credentials.json:ro
         - connect-data:/home/opuser/.op/data
   ```
3. In the `devbox` service, swap the service account token for:
   ```yaml
       OP_CONNECT_HOST: http://onepassword-connect:8080
       OP_CONNECT_TOKEN: ${OP_CONNECT_TOKEN:?}
   ```
4. **Nothing else changes.** `op run`, `op read` and the `op://` references all
   work identically — the CLI just talks to Connect instead of the API. That's
   the point of keeping everything behind `op://` references.

**The catch:** Connect serves whole vaults, so its token is broader than a
scoped service account. Give it a vault containing only what the devbox needs.

---

# Future: 1Password Environments

**Status as of July 2026: still beta**, Mac and Linux only. `op environment read`
and `op run --environment <name>` exist as of the February 2026 CLI releases.

**What it is.** Environment variables managed as a first-class object in
1Password instead of as loose vault items. It can present them as a `.env` file
without writing one — it creates a named pipe, so your app reads what looks like
a normal `.env` while nothing ever lands on disk. It also does AWS Secrets
Manager sync and GitHub Actions integration.

**Why we're not using it yet:**

- It's beta, and the failure mode is "cannot start work". Not where you want a
  beta dependency.
- **It does not solve the latency problem.** The win we care about came from
  batching N requests into one, and `op run --env-file` already does that, as
  GA, on every platform including CI.

**Why waiting costs nothing.** The migration is one flag:

```diff
- op run --no-masking --env-file="$OP_ENV_DIR/${env_name}.env" -- "$@"
+ op run --no-masking --environment "$env_name" -- "$@"
```

in the `opwith` function in `configs/zsh/.zshrc`, plus deleting
`configs/op-env/*.env`. There is no lock-in to escape, so the rational move is to
stay on the GA path until Environments is GA too.

**Re-evaluate when:** the beta badge comes off, *and* one of these is true —
you're managing enough environments that flat `.env` files have become unwieldy,
you want the same variables shared with GitHub Actions from one source of truth,
or you want secrets to reach a process without ever existing as a file.

**Checking status:**

```bash
op --version
op environment --help    # non-zero exit → your CLI predates the feature
```

Sources: [1Password Environments](https://www.1password.dev/environments) ·
[CLI beta releases](https://releases.1password.com/developers/cli-beta/) ·
[.env support announcement](https://1password.com/blog/1password-environments-env-files-public-beta)
