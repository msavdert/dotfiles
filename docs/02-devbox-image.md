# 02 — The devbox image

`ghcr.io/msavdert/devbox` — an Ubuntu 24.04 image with the entire toolchain
already installed. Built by CI for `linux/amd64` and `linux/arm64`.

## The core idea

Everything expensive happens at **build** time. A running container never
downloads a toolchain, never clones this repo, never runs a provisioning script.

That's what makes `docker compose up` reach a usable shell in seconds instead of
the ten-plus minutes the old runtime bootstrap took — and why the environment
you get today is identical to the one you got last week.

## Layer layout

Ordered cheapest-and-most-stable first, so a change to the tool list doesn't
invalidate the apt layer, and a change to a dotfile doesn't invalidate the
toolchain layer.

| Layer | Contents | Rebuilds when |
|---|---|---|
| System | apt packages, locale | `Dockerfile` apt list changes |
| User | `dev` user at uid 1000 | ~never |
| mise | mise binary | ~never |
| **Toolchain** | `mise install` — the expensive one | `configs/mise/devbox.toml` changes |
| Shell | zsh/git/ssh/op/starship/zellij/nvim configs | any config file changes |
| Plugins | zsh plugins, completions, nvim plugins | configs change |

If you edit `.zshrc`, only the last two layers rebuild — about twenty seconds.

## Things in the Dockerfile that look odd but aren't

**`userdel -r ubuntu`.** `ubuntu:24.04` ships a stock `ubuntu` account already
occupying uid 1000. Without removing it, `dev` lands on 1001 and every
bind-mounted file from the host shows up owned by the wrong user.

**`mise install` runs twice.** The `npm:` and `http:` backends shell out to
node, bun and java. Those runtimes have to exist before mise can resolve
anything that depends on them, so runtimes are installed explicitly first.

**`CMD ["sleep", "infinity"]`.** The container's job is to stay alive; you enter
it with `docker exec`. Running zellij as PID 1 would tie the container's whole
lifetime to a single terminal — close that terminal and your "persistent"
environment stops.

**zsh plugins are pinned to tags** (`ZSH_AUTOSUGGESTIONS_REF` etc.) and their
`.git` directories are deleted. A `git clone` of a moving branch at build time
would make the build non-reproducible for no benefit.

**`Lazy! restore` before `Lazy! sync`.** `restore` installs exactly the commits
in `configs/nvim/lazy-lock.json`. `sync` resolves to whatever is newest. The
fallback exists only for the very first build, before a lockfile is committed —
see below.

## Commit the Neovim lockfile

This matters and is easy to forget. Until `configs/nvim/lazy-lock.json` exists,
every image build resolves plugins to whatever HEAD happens to be that day.

After the first successful build:

```bash
docker run --rm -v "$PWD/configs/nvim:/out" ghcr.io/msavdert/devbox:latest \
  cp /home/dev/.config/nvim/lazy-lock.json /out/
git add configs/nvim/lazy-lock.json && git commit -m "chore: pin nvim plugins"
```

From then on builds are deterministic. To move plugins forward deliberately:
`nvim` → `:Lazy sync` → copy the updated lockfile back out and commit it.

## Building

**Locally, single arch (fast — this is what you want while iterating):**

```bash
docker build -t devbox .
docker run -it --rm devbox zsh
```

**Locally, both architectures via emulation:**

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t devbox .
```

QEMU makes the foreign architecture roughly 5–10× slower. Fine for a
correctness check, painful as a routine.

**In CI** — `.github/workflows/build.yml` avoids emulation entirely: each
architecture builds on a *native* runner (`ubuntu-24.04` and `ubuntu-24.04-arm`)
and pushes **by digest**, then a final `merge` job stitches the digests into one
multi-arch manifest with `docker buildx imagetools create`.

> `ubuntu-24.04-arm` runners are free for **public** repositories. If this repo
> is private and you haven't enabled ARM runners for the org, the arm64 job will
> fail to schedule. Fallback: delete the matrix, use a single `ubuntu-24.04`
> runner with `docker/setup-qemu-action@v3` and
> `platforms: linux/amd64,linux/arm64`. Slower, but it works anywhere.

## Tags

| Tag | Meaning | Use for |
|---|---|---|
| `latest` | newest build of `main` | day-to-day |
| `20260730` | that day's build | pinning to a known-good day |
| `sha-<commit>` | exact commit | bisecting a regression |
| `@sha256:…` | exact image digest | the only truly immutable reference |

Roll back by pinning a digest in `compose.yaml`:

```yaml
image: ghcr.io/msavdert/devbox@sha256:abc123…
```

## When the image rebuilds

- Any push to `main` touching the `Dockerfile` or `configs/`
  (docs and `macos/` are excluded via `paths-ignore`)
- **Weekly, Mondays 04:00 UTC** — this is what actually picks up new versions of
  every tool pinned to `latest`. Without the schedule, `latest` would freeze at
  whatever it resolved to during the last code change.
- Manually, via *Actions → build → Run workflow*

Pull requests build but publish nothing — the `outputs` line switches to
`type=cacheonly`. You get "does it still build?" without polluting the registry.

## Image size

Expect roughly 4–6 GB. The language runtimes (java, rust, go, python, node) and
the AI CLIs dominate. Deliberately not optimised for size — pulls happen once
per VPS, and layer caching means updates transfer only what changed.

If it becomes a problem, in order of payoff:

1. Drop `java` and `http:sqlcl` (~800 MB) if Oracle work has stopped.
2. Drop `rust` unless you compile Rust in the devbox.
3. Split into `devbox-base` and `devbox-full`, and let `compose.yaml` choose.

Don't do any of that pre-emptively — a fat image that always works beats a
slim one that's missing the tool you need at 2am.
