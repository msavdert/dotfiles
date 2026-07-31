---
name: devbox-image
description: Use when adding, removing, upgrading or debugging a tool in the devbox container image - anything that touches configs/mise/devbox.toml, the Dockerfile layers, shell completions, or the local docker build/test loop before pushing to CI.
---

# Changing the devbox image

The container is built entirely at `docker build` time. Nothing is installed when
a container starts, so every tool change is an image change, and every image
change needs a rebuild and a redeploy.

Reference docs: `docs/02-devbox-image.md` (layers, tags, CI),
`docs/06-maintenance.md` (procedures, version policy).

## 1. Decide which manifest owns the tool

| Where it runs | Manifest | Notes |
|---|---|---|
| Inside the container (default answer) | `configs/mise/devbox.toml` | Every dev tool, runtime, CLI. |
| macOS CLI tool | `configs/mise/macos.toml` | Only if it genuinely belongs on the laptop. |
| macOS GUI app or host daemon | `macos/Brewfile` | `cask "..."` and daemons only. |

Two invariants apply (`CLAUDE.md` 6 and 8):

- If something is needed for coding, it goes in `configs/mise/devbox.toml`, not
  `macos/Brewfile`.
- `macos/Brewfile` and `configs/mise/macos.toml` must never list the same tool.
  A tool in both lands twice on `$PATH` and the mise shim wins silently. Before
  adding to either, grep the other.

## 2. Pick the version string

Policy from `docs/06-maintenance.md`:

- Language runtimes (`python`, `node`, `go`, `java`) are pinned to a **major**
  version. A silent major bump invalidates virtualenvs, `node_modules` and
  compiled output, which breaks work in progress.
- Everything else tracks `"latest"`. `latest` is re-resolved **only** when the
  image builds, and the published image digest is the real pin. The weekly
  Monday 04:00 UTC scheduled build in `.github/workflows/build.yml` is what
  actually moves those tools forward.
- Non-registry sources use a mise backend (`npm:`, `cargo:`, `http:`, GitHub
  releases). Syntax: `docs/reference/mise-custom-backends.md`. Existing examples
  in `configs/mise/devbox.toml`:

  ```toml
  "npm:@oh-my-pi/pi-coding-agent" = "latest"
  "http:sqlcl" = { version = "26.2.0.181.2110", url = "https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-26.2.0.181.2110.zip" }
  ```

Add the entry under the matching comment section (`Language runtimes`,
`Search & text processing`, `Kubernetes & infrastructure`, ...) rather than at
the end of `[tools]`.

**Check arm64 first.** CI builds `linux/amd64` and `linux/arm64` on native
runners; a tool with no arm64 artifact fails the arm64 job.

```bash
mise ls-remote <tool>
```

## 3. Know which Dockerfile layer you are invalidating

Layers in `Dockerfile` are ordered cheapest-and-most-stable first:

| Layer | Contents | Rebuilds when |
|---|---|---|
| System | `apt-get install` (build-essential, curl, git, zsh, ...) | the apt list in `Dockerfile` changes |
| User | `dev` at uid 1000 | ~never |
| mise | the mise binary from `https://mise.run` | ~never |
| **Toolchain** | `COPY configs/mise/devbox.toml` + `mise install` | `configs/mise/devbox.toml` changes |
| Shell | zsh / git / ssh / op-env / starship / zellij / nvim configs | any of those config files change |
| Plugins | zsh plugins, `regen-completions.zsh`, `Lazy! restore` | configs change |

A tool addition normally only touches the toolchain layer and everything below
it. Do **not** move `mise install` down or a config layer up: a `.zshrc` edit
would then re-run several hundred MB of toolchain downloads instead of rebuilding
in about twenty seconds.

Only reach for the apt layer when the tool is a system library or something mise
cannot provide. That invalidates the whole image.

Note the two-phase `mise install` in the toolchain layer: runtimes
(`node bun python go java rust`) install first because the `npm:` and `http:`
backends shell out to them. A new `npm:`-backed tool needs no change there; a new
*runtime* that other backends depend on must be added to the first phase.

## 4. Completions

If the tool ships a zsh completion generator, add it to the `gens` map in
`configs/zsh/regen-completions.zsh`:

```zsh
typeset -A gens=(
    kubectl   "kubectl completion zsh"
    ...
    newtool   "newtool completion zsh"
)
```

The script writes to `~/.local/share/zsh/completions` (on `$fpath`), runs once
during `docker build`, and skips tools that are not installed. Never add
`source <(newtool completion zsh)` to `.zshrc` - shell start-up does no work
(`CLAUDE.md` invariant 3).

Inside an already-running container:

```bash
mise run completions:regen
exec zsh
```

## 5. Local build and test loop

```bash
docker build -t devbox-test .
docker run -it --rm devbox-test zsh -c 'newtool --version'
```

Cross-check arm64 when the tool looked risky:

```bash
docker run --rm --platform linux/arm64 devbox-test newtool --version
```

Both architectures locally (QEMU, roughly 5-10x slower - correctness check only):

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t devbox .
```

For a runtime **upgrade** (for example `python = "3.14"` -> `"3.15"`), test
against the real work volume before committing:

```bash
docker run -it --rm -v devbox_work:/home/dev/work devbox-test zsh
# rebuild virtualenvs, run your test suites, confirm nothing broke
```

Two names to remember when verifying: `sqlcl`'s binary is `sql`, and `rust`
provides `rustc`/`cargo`/`rustup` - there is no `rust` command.

## 6. Ship it

```bash
git commit -am "feat: add newtool" && git push
```

CI (`.github/workflows/build.yml`) builds both architectures on native runners,
pushes by digest, and merges them into one multi-arch manifest. Pull requests
build but publish nothing.

Then deploy - see `skill://vps-deploy`:

```bash
ssh vps 'cd ~/devbox && docker compose pull && docker compose up -d'
```

## Gotchas

- **Nothing installed inside a running container survives.** `~/.local/share/mise`
  is not a persistent volume. If you `mise use -g` something in the devbox to try
  it out, it disappears on the next image pull. Put it in
  `configs/mise/devbox.toml`.
- **Neovim plugins are not mise tools.** They come from
  `configs/nvim/lazy-lock.json`, installed with `Lazy! restore`. To move them
  forward, `:Lazy sync` in the devbox, then copy the lockfile back into the repo
  and commit it (`docs/06-maintenance.md`), otherwise the change is lost at the
  next pull.
- **Docs change in the same commit as behaviour** (`CLAUDE.md` invariant 7). A
  tool that changes a documented workflow means editing the doc too.
- **Image size** is roughly 4-6 GB and deliberately not optimised. Do not start
  splitting the image because you added one CLI.
