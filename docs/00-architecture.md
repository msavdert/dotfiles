# 00 — Architecture

## The problem this solves

Two things kept going wrong with the previous setup:

1. **The Mac drifted.** Tools installed for one experiment stayed forever.
   Config files got hand-edited. After a year nobody could say what was on the
   machine or why, and reinstalling meant losing things nobody had written down.

2. **Nothing was reproducible.** `bootstrap.sh` downloaded ~40 tools *at
   runtime*, each pinned to `latest`. Two machines provisioned a week apart got
   different versions. A rebuilt container meant a 10-minute wait and a
   different environment than the one that worked yesterday.

The goal: **keep macOS pristine, do all real work in a disposable environment
that comes up in seconds and is identical every time.**

## The two tiers

```
┌─────────────────────────────────────┐
│  Tier 0 — macOS (thin client)       │
│                                     │
│  ghostty · 1Password · OrbStack     │
│  mise: starship zoxide eza bat      │
│        gh jq fzf rg fd uv shellcheck│
│  configs: zsh, git, ssh, starship   │
│                                     │
│  Declared in: macos/Brewfile        │
│               configs/mise/macos.toml│
└──────────────┬──────────────────────┘
               │ ssh dev
               │ (ControlMaster keeps it instant)
               ▼
┌─────────────────────────────────────┐
│  Tier 1 — devbox container          │
│                                     │
│  ghcr.io/msavdert/devbox:latest     │
│  everything else: languages, nvim,  │
│  zellij, k8s tooling, AI CLIs       │
│                                     │
│  Declared in: Dockerfile            │
│               configs/mise/devbox.toml│
│  Runs on: VPS via compose.yaml      │
└─────────────────────────────────────┘
```

The dividing line is a single question: **"do I need this on the laptop itself,
or do I need it where the code is?"** Almost everything is the second answer.

## Where each thing lives

| Concern | File | Applies to |
|---|---|---|
| macOS packages | `macos/Brewfile` | Tier 0 |
| macOS CLI tools | `configs/mise/macos.toml` | Tier 0 |
| macOS provisioning | `macos/setup.sh` | Tier 0 |
| devbox tools | `configs/mise/devbox.toml` | Tier 1 |
| devbox image | `Dockerfile` | Tier 1 |
| devbox deployment | `compose.yaml` | Tier 1 |
| Image publishing | `.github/workflows/build.yml` | CI |
| Shell | `configs/zsh/` | **both** |
| Git, SSH, starship | `configs/git/`, `configs/ssh/`, `configs/starship.toml` | **both** |
| Editor, multiplexer | `configs/nvim/`, `configs/zellij/` | Tier 1 only |
| AI Agent configs | `configs/omp/`, `configs/claude/`, `configs/gemini/` | both |
| Secret references | `configs/op-env/*.env` | both |

Shared configs are guarded (`(( $+commands[x] ))`) so a tool that only exists in
the container is simply skipped on the Mac.

---

# Decision records

Each entry: what was decided, why, what was rejected, and what would make us
change our mind.

## D1 — Bake tools into an image, don't bootstrap at runtime

**Decision.** `docker build` runs `mise install`. A running container never
downloads a toolchain.

**Why.** The old model (`curl … bootstrap.sh | bash` on a live Ubuntu box) had
three failure modes that all disappear here:

- *Slow.* Every container recreation re-downloaded several hundred MB.
- *Non-reproducible.* `latest` resolved differently on every run, so the
  environment silently changed under you.
- *Unrecoverable.* If a tool's release broke, your environment broke, and there
  was nothing to roll back to.

With an image, the published **digest** is the pin. Yesterday's environment is
`docker run ghcr.io/msavdert/devbox@sha256:…` and it will be byte-identical
forever.

**Rejected: a VM with a provisioning script (Ansible/cloud-init).** Slower to
build, slower to reset, and it re-introduces "run steps against a live machine",
which is the exact thing that made state drift possible.

**Rejected: Nix.** It genuinely solves reproducibility, and better than this
does. It also costs a language, a mental model, and a debugging story that has
to be re-learned every time something breaks. Explicitly not worth it here —
this environment has one user and a low tolerance for yak-shaving. Revisit if
you ever need bit-identical rebuilds of the *image itself*, not just a pinned
digest.

**Change our mind if:** image builds start taking so long that iterating on the
tool list becomes painful. The mitigation is layer ordering (already done — the
expensive `mise install` is its own layer) before it's a reason to switch.

## D2 — Container, not a VM

**Decision.** The devbox is a Docker container.

**Why.** Faster start, image-based reproducibility, trivial reset
(`docker compose down && up`), and the same artifact runs on the Mac under
OrbStack for testing.

**When a VM would be right instead:** nested virtualisation, a custom kernel, or
systemd-as-PID-1. None apply — Kubernetes work here targets *remote* clusters
via `kubectl`, so no local cluster runtime is needed. If that changes, mounting
the host Docker socket (commented out in `compose.yaml`) covers most of the gap.

## D3 — macOS keeps Homebrew *and* mise

**Decision.** Homebrew owns GUI applications (casks) and daemons that need
system integration. mise owns every CLI tool. Nothing is owned by both.

**Why.** They aren't competitors. mise cannot install the 1Password desktop app
or OrbStack; casks are the one thing Homebrew is unambiguously best at.
Meanwhile mise handles CLI versioning better and is already the mechanism used
inside the container, so one mental model covers both tiers.

The rule that matters is **no overlap**. A tool available from both ends up
twice on `$PATH`, with the mise shim silently winning — you then debug a version
you aren't looking at. `macos/Brewfile` names the tools that moved to mise
precisely so `brew bundle cleanup` proposes removing the brew copies.

mise itself does *not* come from brew: the standalone installer
(https://mise.run) puts it in `~/.local/bin`, exactly as the Dockerfile does.
git is Apple's `/usr/bin/git`. Two fewer things to own.

**The part that actually fixes drift** isn't the tool choice, it's
`brew bundle cleanup`: anything installed but not written down gets removed.
That turns Homebrew from an append-only pile into a declarative manifest.

> Homebrew 6 deprecated the `--cleanup` *switch* on `brew bundle`. The
> `brew bundle cleanup` **subcommand** is the supported form, and without
> `--force` it only prints what it would uninstall. `macos/setup.sh` uses the
> subcommand.

**Rejected: mise for everything on macOS.** Would mean installing GUI apps by
hand — the exact untracked state we're trying to eliminate.

**Rejected: Homebrew for everything.** Would put a second, divergent copy of the
toolchain on the laptop, which is what tier 0 exists to prevent.

## D4 — Secrets are never in the environment

**Decision.** No secret is exported at shell start. Commands that need one are
wrapped: `op run --env-file=~/.config/op-env/ai.env -- claude`.

**Why.**

- *Speed.* The old `personal.env` did four sequential `op read` calls on every
  single new terminal — four network round-trips before you got a prompt.
  `op run` resolves the whole file in one request, and only when you actually
  run the command.
- *Blast radius.* An exported variable is visible to every child process and via
  `/proc/<pid>/environ`. Injected variables live in one process and die with it.

**Rejected: caching resolved secrets to a tmpfs file with a TTL.** Faster still,
but it puts plaintext secrets on a filesystem and adds an invalidation problem.
Not worth it for a handful of API keys. Details and the migration paths for
1Password Connect and Environments are in [05-secrets.md](05-secrets.md).

## D5 — Shell start-up does no work

**Decision.** No network calls, no `source <(tool completion zsh)`, no eager
secret loading in `.zshrc`. Completions are pre-generated into a directory on
`$fpath` at image build time.

**Why.** The old config forked a process for each of six tools' completions on
every shell start, then ran a full `compinit` security scan. `$fpath` lets zsh
load each completion lazily, only when you press TAB on that command.

Measured in the built image: **44ms** steady-state, ~340ms for the first shell
after a fresh image (it builds the completion cache once).

One trap worth recording, because the broken version is what most guides
publish: the usual compinit-caching idiom

```zsh
if [[ -n ${zcompdump}(#qN.mh+24) ]]; then compinit; else compinit -C; fi
```

**never works.** `[[ ]]` performs no filename generation, so the glob qualifier
is just a non-empty string and the slow branch always runs. The glob has to be
expanded in an array assignment — see `configs/zsh/.zshrc`.

Regenerate completions by hand after adding a tool: `mise run completions:regen`.

## D6 — The home directory is not one big volume

**Decision.** `compose.yaml` mounts narrow persistent paths: `~/work`, `~/.local/state`, `~/.kube`, `~/.omp/agent`, `~/.claude`, and `~/.gemini`.


**Why.** A volume mounted at `/home/dev` shadows everything the image put there.
Pull a new image with an updated `.zshrc` and a fixed toolchain, and you'd still
be running last month's config, because the volume wins. Persisting narrowly
(work, state, kube, and AI agent auth/session stores) means image upgrades
and live config sync (`mise run dotfiles:sync`) take effect while preserving login credentials.

**Consequence to remember:** code goes in `~/work`. Declarative configs are managed in this repo and synced via `mise run dotfiles:sync`.

## D7 — Language runtimes are pinned, CLI tools are not

**Decision.** `python`, `node`, `go`, `java` are pinned to a major version in
`configs/mise/devbox.toml`. Everything else tracks `latest`.

**Why.** A major bump in a runtime invalidates virtualenvs, `node_modules` and
compiled artifacts — it breaks work in progress. A CLI tool moving from 0.41 to
0.42 does not. And since `latest` is only re-resolved when the image is rebuilt,
the published digest still pins them for anyone running that image.

See [06-maintenance.md](06-maintenance.md) for the upgrade procedure.

## D8 — Modern CLI tools do not shadow POSIX names

**Decision.** `rg`, `fd` and `bat` keep their own names. No
`alias grep='rg'`.

**Why.** Two concrete problems, not style preferences:

1. Flags differ. `rg -E` means `--encoding`, not "extended regex", so a pasted
   `grep -iE 'pattern' file` silently fails.
2. **zsh expands aliases inside function bodies at definition time.** The old
   `ssh()` picker called `grep -iE` and `grep -v '*'`; with `alias grep='rg'`
   defined earlier in the same file, those became `rg` calls that errored out,
   and the host list was always empty. The alias silently rewrote the function.

Functions in `.zshrc` now prefix `command` for the same reason.

## D9 — SSH agent forwarding is off by default

**Decision.** `ForwardAgent no` in the `Host *` block; enable per-host in
`~/.ssh/config.local`.

**Why.** A forwarded agent can be used by root on the remote host to
authenticate as you, to anywhere your keys work, for as long as you're
connected. That's an acceptable risk for one machine you control, and a bad
default for every host you'll ever type.

On the Mac, keys live in the 1Password agent
(`configs/ssh/config.macos`) and never touch the disk at all.

## D10 — Documentation lives in the repo, in numbered files

**Decision.** These files, committed alongside the code they describe.

**Why.** The previous `CLAUDE.md` claimed a `secrets:pull` task that didn't
exist, described a lazy-loading token mechanism that had been replaced, and
referenced `lazy-lock.json` and `lazyvim.json` files that weren't committed.
Documentation that lives apart from the thing it documents rots silently.
Keeping it in-tree means a PR that changes behaviour can change the docs in the
same commit — and reviewing it is the same act as reviewing the code.

---

## What was deliberately left out

- **1Password Connect.** Would make `op` reads local instead of round-tripping
  to 1Password's API. Not needed at current usage; the migration is written up
  in [05-secrets.md](05-secrets.md) for when it is.
- **Tailscale.** Would remove the VPS's public SSH port and make the devbox
  reachable by name from anywhere. Recommended eventual upgrade; the plain-SSH
  path in [03-vps-deployment.md](03-vps-deployment.md) needs no new
  infrastructure and works today.
- **1Password Environments.** Still beta. See
  [05-secrets.md](05-secrets.md#future-1password-environments) for why waiting
  costs nothing.
- **A devcontainer.json.** The image is already the contract; adding an
  editor-specific wrapper would be a third place where the tool list lives.
