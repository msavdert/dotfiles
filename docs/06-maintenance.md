# 06 — Maintenance

## Adding a tool to the devbox

```bash
# 1. add it
$EDITOR configs/mise/devbox.toml

# 2. test locally before pushing
docker build -t devbox-test .
docker run -it --rm devbox-test zsh -c 'newtool --version'

# 3. if it has shell completions, add it to the generator
$EDITOR configs/zsh/regen-completions.zsh

# 4. ship it
git commit -am "feat: add newtool" && git push
```

CI builds and publishes both architectures. Then on the VPS:

```bash
ssh vps 'cd ~/devbox && docker compose pull && docker compose up -d'
```

**Check arm64 availability first.** Not every tool publishes arm64 binaries. If
the arm64 CI job fails on a specific tool, either drop the tool or exclude it
per-architecture. Quick check:

```bash
mise ls-remote <tool>
docker run --rm --platform linux/arm64 devbox-test <tool> --version
```

Backend syntax for npm / cargo / GitHub releases / plain URLs:
[reference/mise-custom-backends.md](reference/mise-custom-backends.md).

## Adding a tool to macOS

Think twice — the default answer is "put it in the devbox instead". If it
genuinely belongs on the laptop:

- GUI app → `macos/Brewfile` (`cask "..."`)
- CLI tool → `configs/mise/macos.toml`

Then `./macos/setup.sh`.

Anything installed by hand and *not* written down gets removed the next time
`CLEANUP=1 ./macos/setup.sh` runs. That's the feature.

## Version policy

| Kind | Policy | Why |
|---|---|---|
| `python`, `node`, `go`, `java` | pinned to major | a major bump invalidates virtualenvs, `node_modules`, compiled output — it breaks work in progress |
| everything else | `latest` | resolved only at image build; the published digest is the real pin |
| nvim plugins | `lazy-lock.json` | committed; `Lazy! restore` installs exactly those commits |
| zsh plugins | git tags in `Dockerfile` | `ZSH_*_REF` build args |
| base image | `ubuntu:24.04` | LTS; revisit at 26.04 |

Because `latest` is only re-resolved when the image builds, **the weekly
scheduled build is what actually keeps tools current.** Without it, `latest`
would freeze at whatever it resolved to during the last code change.

## Upgrading a language runtime

Deliberate, never automatic:

```bash
$EDITOR configs/mise/devbox.toml     # python = "3.14" → "3.15"
docker build -t devbox-test .
docker run -it --rm -v devbox_work:/home/dev/work devbox-test zsh
# rebuild virtualenvs, run your test suites, confirm nothing broke
```

Only then commit. If it goes wrong after deployment, roll back to the previous
image digest (below) — the volumes are untouched.

## Updating nvim plugins

```bash
ssh dev
nvim          # :Lazy sync
```

Then get the updated lockfile back into the repo:

```bash
ssh vps 'docker exec devbox cat /home/dev/.config/nvim/lazy-lock.json' \
  > configs/nvim/lazy-lock.json
git commit -am "chore: update nvim plugins"
```

Without this the change is lost at the next image pull — `~/.config/nvim` is not
a persistent volume, by design.

## Rolling back

```bash
docker buildx imagetools inspect ghcr.io/msavdert/devbox:latest   # find digests
```

```yaml
# compose.yaml
image: ghcr.io/msavdert/devbox@sha256:<known-good>
```

```bash
docker compose up -d
```

Tags also work: `:20260715` for a specific day, `:sha-<commit>` for a specific
commit — useful for bisecting when something broke sometime last month.

## Regenerating completions

After adding a tool that ships zsh completions:

```bash
mise run completions:regen
exec zsh
```

This also runs at image build, so it's only needed when you install something
inside a running container.

## Routine health check

Worth running every few months:

```bash
# macOS: has anything crept in?
brew bundle check --file=macos/Brewfile           # "dependencies are satisfied"
brew bundle cleanup --file=macos/Brewfile        # should print nothing
mise ls                                          # matches configs/mise/macos.toml

# devbox
ssh dev 'mise ls --outdated'
ssh vps 'docker system df'                       # reclaim with `docker system prune -a`

# repo
shellcheck macos/setup.sh
zsh -n configs/zsh/.zshrc

# no secrets, ever
git log -p -- configs/op-env/ | grep -E 'sk-|ghp_|github_pat_'
```

## Rotating the service account token

```bash
# 1Password → Developer → Service Accounts → rotate
ssh vps
cd ~/devbox
$EDITOR .env                 # new OP_SERVICE_ACCOUNT_TOKEN
docker compose up -d         # recreates with the new value
docker exec devbox op whoami # verify
```

Do this if the VPS is ever compromised, if the token is older than a year, or
whenever you're unsure. It's cheap.

## Changing the docs

When behaviour changes, change the doc in the **same commit**. The old
`CLAUDE.md` described a `secrets:pull` task that had been deleted and a
lazy-loading token mechanism that had been replaced — both were wrong for
months, and being wrong is worse than being absent, because you act on it.
