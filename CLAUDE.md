# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this repo is

Two tiers, one repo:

- **Tier 0 — macOS thin client.** GUI apps plus a short list of CLI tools.
  Declared in `macos/Brewfile` (casks and host daemons) and
  `configs/mise/macos.toml` (every CLI), applied by `macos/setup.sh`. The two
  manifests must not overlap — see invariant 8.
- **Tier 1 — devbox container.** Everything else: language runtimes, neovim,
  zellij, kubernetes tooling, AI CLIs. Declared in `configs/mise/devbox.toml`,
  baked into `Dockerfile`, published to `ghcr.io/msavdert/devbox`, deployed with
  `compose.yaml`.

Full rationale and decision records: `docs/00-architecture.md`.

## Common commands

| Task | Command |
|---|---|
| Provision macOS | `./macos/setup.sh` (`DRY_RUN=1`, `--links-only`, `CLEANUP=1`) |
| Build image locally | `docker build -t devbox .` |
| Run image locally | `docker run -it --rm ghcr.io/msavdert/devbox:latest zsh` |
| Deploy / update VPS | `docker compose pull && docker compose up -d` |
| Connect | `ssh dev` |
| Regenerate completions | `mise run completions:regen` |
| Pull kubeconfig | `mise run kube:homelab` |
| Restore OMP Synthetic key | `mise run omp:auth` (then `/login` for the OAuth providers) |
| Check effective OMP config | `omp config list` · `omp config path` · `omp models` |
| Lint | `shellcheck macos/setup.sh` · `zsh -n configs/zsh/.zshrc` |

## Invariants — do not break these

1. **No runtime bootstrapping.** Tools are installed during `docker build`.
   Never add a step that downloads a toolchain when a container starts.
2. **No secrets in the environment.** Never add `export SOME_TOKEN=...` or an
   eager `op read` to `.zshrc`. Secrets are injected per-command via `op run`
   using the `op://` references in `configs/op-env/*.env`. Those files must never
   contain a value.
3. **Shell start-up does no work.** No network calls, no
   `source <(tool completion zsh)`, no subprocess-per-tool. Completions are
   pre-generated into `~/.local/share/zsh/completions` by
   `configs/zsh/regen-completions.zsh`.
4. **Modern tools do not shadow POSIX names.** No `alias grep='rg'`. zsh expands
   aliases inside function bodies at definition time, which silently rewrites
   the functions in `.zshrc`. Use `command` prefixes inside functions.
5. **Persist narrowly.** `compose.yaml` mounts only `~/work`,
   `~/.local/state` and `~/.kube`. Mounting `/home/dev` would shadow the image's
   configs and make upgrades ineffective.
6. **Don't put dev tools on macOS.** If something is needed for coding, it goes
   in `configs/mise/devbox.toml`, not `macos/Brewfile`.
7. **Update docs in the same commit as the behaviour.** The previous version of
   this file documented a task that didn't exist and a mechanism that had been
   replaced.
8. **`macos/Brewfile` and `configs/mise/macos.toml` must not overlap.** A tool
   in both lands twice on `$PATH` and the mise shim wins silently. Brewfile =
   casks + host daemons only; every CLI belongs to mise.
9. **Never write machine-specific values into tracked configs.** Real
   hostnames, signing keys and installer-injected `PATH` lines go in
   `~/.ssh/config.local`, `~/.gitconfig.local` and `~/.zshrc.local`, all of
   which are read but never committed.
10. **The OMP config contract.** Declarative agent files are tracked in
    `configs/omp/` and reach `~/.omp/agent/` two ways: the `Dockerfile` copies
    the directory into the image, and `link_configs()` in `macos/setup.sh`
    symlinks each file individually. Never set `PI_CODING_AGENT_DIR`. Runtime
    state OMP writes into that same directory (`agent.db*`, `history.db*`,
    `models.db*`, `sessions/`, `.env`) is never committed. A file in
    `configs/omp/agents/` must never be named after a bundled agent (`scout`,
    `sonic`, `task`, `librarian`, `reviewer`, `designer`) — it replaces the
    definition wholesale and drops flags like `blocking: true`; to change only
    the model, use `task.agentModelOverrides` in `config.yml`. See
    `docs/08-omp-agent.md`.
11. **The Claude Code config contract.** `configs/claude/` holds
    `settings.json`, `statusline-command.sh` and `agents/` (custom
    subagents), tracked and reaching `~/.claude/` the same two ways as OMP:
    `Dockerfile` copies the whole directory into the image, `link_configs()`
    in `macos/setup.sh` symlinks each of the three per file/dir. Never
    symlink `~/.claude` itself — it also holds runtime state
    (`history.jsonl`, `sessions/`, `shell-snapshots/`, `telemetry/`, OAuth
    credentials) that must never land in this repo's working tree.
12. **The Antigravity (AGY) config contract.** `configs/gemini/` holds
    `antigravity-cli/settings.json`, `antigravity-cli/statusline.sh` and
    customizations, tracked and reaching `~/.gemini/` the same two ways as
    OMP and Claude: `Dockerfile` copies the whole directory into the image,
    `link_configs()` in `macos/setup.sh` symlinks individual files/directories.
    Never symlink `~/.gemini` itself — it also holds runtime state (`brain/`,
    `transcripts/`, `auth.json`, OAuth credentials) that must never land in
    this repo's working tree.

## Layout

```
Dockerfile                        image definition (tier 1)
compose.yaml                      VPS deployment
macos/{Brewfile,setup.sh}         tier 0
configs/
  mise/{devbox,macos}.toml        toolchains, split by tier
  zsh/{.zshenv,.zshrc,regen-completions.zsh}
  op-env/*.env                    op:// references only
  nvim/ zellij/                   tier 1 only (not linked on macOS)
  omp/                            coding-agent config -> ~/.omp/agent/
  claude/                         Claude Code config -> ~/.claude/
  gemini/                         Antigravity (AGY) config -> ~/.gemini/
  git/config ssh/config* starship.toml
.github/workflows/build.yml       native multi-arch build → ghcr.io
docs/00..08                       architecture through the coding agent
docs/reference/                   zellij keybindings, mise backends
```

## Conventions

- **zsh configs**: guard every tool with `(( $+commands[x] ))` — the same
  `.zshrc` runs on macOS and in the container.
- **Version policy**: language runtimes pinned to a major version, CLI tools on
  `latest` (re-resolved only at image build; the digest is the real pin). See
  `docs/06-maintenance.md`.
- **Neovim**: LazyVim. `configs/nvim/lazy-lock.json` is committed and installed
  with `Lazy! restore` at build time — update it deliberately, don't let builds
  drift.
- **Shell scripts**: bash with `set -euo pipefail`, shellcheck-clean.
- **Dockerfile**: keep the expensive `mise install` in its own layer, below the
  system layer and above the config layers.
