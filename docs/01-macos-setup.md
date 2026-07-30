# 01 — macOS setup (the thin client)

The Mac's entire job: open a terminal, unlock secrets, connect to the devbox.
It is not where code gets compiled.

## Install

```bash
git clone https://github.com/msavdert/dotfiles.git ~/dotfiles
cd ~/dotfiles
./macos/setup.sh
```

What it does, in order:

1. Installs Homebrew if missing.
2. Applies `macos/Brewfile`, then **shows** what isn't in it. Re-run with
   `CLEANUP=1` to actually remove those.
3. Links the config files (see the table below).
4. Installs the CLI tools from `configs/mise/macos.toml` (currently 11).
5. Checks whether the 1Password SSH agent is enabled.

Useful variations:

```bash
DRY_RUN=1 ./macos/setup.sh      # print everything, change nothing
./macos/setup.sh --links-only   # just refresh symlinks
CLEANUP=1 ./macos/setup.sh      # also uninstall anything not in the Brewfile
```

## Why `CLEANUP` is opt-in

`brew bundle cleanup --force` uninstalls every package not in the Brewfile.
That's the mechanism that keeps the Mac clean — and it's also destructive the
first time you run it, when the Brewfile doesn't yet mention things you actually
want. So the default run only *prints* the list. Read it, move the keepers into
`macos/Brewfile`, then run with `CLEANUP=1`.

After that first pass, make it a habit: **installed but not in the Brewfile
means gone at the next setup run.** That's the whole discipline.

## What gets linked

| Repo file | Link target |
|---|---|
| `configs/zsh/.zshenv` | `~/.zshenv` |
| `configs/zsh/.zshrc` | `~/.zshrc` |
| `configs/git/config` | `~/.gitconfig` |
| `configs/starship.toml` | `~/.config/starship.toml` |
| `configs/op-env/` | `~/.config/op-env` |
| `configs/mise/macos.toml` | `~/.config/mise/config.toml` |
| `configs/ssh/config` | `~/.ssh/config` |
| `configs/ssh/config.macos` | `~/.ssh/config.macos` |

**Not linked, on purpose:** `~/.config/nvim` and `~/.config/zellij`. Editing and
multiplexing happen in the devbox. If you find yourself wanting nvim on the
laptop, that's a signal you're doing work in the wrong tier — but if you really
need it, add the two lines to `link_configs()` in `macos/setup.sh` and add
`neovim` to `configs/mise/macos.toml`.

Existing files are moved to `~/.dotfiles-backups/<timestamp>/` rather than
overwritten. Nothing is ever deleted by the linker.

> The old `scripts/setup-symlinks.sh` created `~/.config/nvim` with `mkdir -p`
> immediately before trying to symlink that same path — so every fresh machine
> produced a pointless empty `.bak` directory. `link_configs()` only creates
> *parent* directories.

## SSH keys: 1Password agent

Turn it on: **1Password → Settings → Developer → "Use the SSH agent"**.

`configs/ssh/config.macos` then points `IdentityAgent` at the agent socket.
Consequences:

- No private key file exists anywhere on the Mac. A stolen laptop backup
  contains nothing usable.
- Every key use prompts for Touch ID.
- Keys are shared across your devices through 1Password, so a new Mac needs no
  key migration at all.

If the agent is off, comment out the `IdentityAgent` line and ssh falls back to
`~/.ssh/id_*`.

## Local overrides

Three files are read but **never committed**. They exist so that nothing
machine-specific — a real hostname, a signing key, a vendor's `PATH` line — ever
has to be written into a tracked config.

| File | Loaded by | Holds |
|---|---|---|
| `~/.zshrc.local` | sourced last by `.zshrc` | installer-injected `PATH` entries (Windsurf, Antigravity, OrbStack), personal aliases and functions |
| `~/.gitconfig.local` | `[include]` at the end of `.gitconfig` | commit signing (1Password `op-ssh-sign`), any per-machine identity |
| `~/.ssh/config.local` | `Include` at the **top** of `.ssh/config` | real hostnames, per-host `ForwardAgent yes`, the `Host dev` block |

Two ordering details that are easy to get backwards:

- **git**: last value wins, so the include sits at the **bottom** of
  `configs/git/config`.
- **ssh**: *first* value wins, so the include sits at the **top** of
  `configs/ssh/config`.

`~/.gitconfig.local` is where commit signing lives because the path to
`op-ssh-sign` is macOS-only — the devbox has no 1Password desktop app, and git
silently ignores a missing include, so the same tracked `.gitconfig` works in
both tiers.

This is also where the `Host dev` block from
[03-vps-deployment.md](03-vps-deployment.md) goes.

> If you are migrating from a hand-written setup, move the machine-specific
> parts of your old `~/.zshrc`, `~/.gitconfig` and `~/.ssh/config` into these
> three files *before* running `./macos/setup.sh`. The originals are backed up
> to `~/.dotfiles-backups/<timestamp>/`, so nothing is lost either way — but
> commit signing and your ssh hosts stop working until they are migrated.

## Running the devbox locally

OrbStack is in the Brewfile precisely so you can run the real image on the
laptop — for testing an image change before deploying, or for working offline:

```bash
docker run -it --rm \
  -v "$PWD:/home/dev/work" \
  ghcr.io/msavdert/devbox:latest zsh
```

Same image, same digest, same tools as the VPS. That's the point of building
`linux/arm64` alongside `linux/amd64`.

## What "clean" looks like

A year from now, this should still be true:

```bash
brew bundle check --file=macos/Brewfile   # "dependencies are satisfied"
brew bundle cleanup --file=macos/Brewfile   # prints nothing
mise ls                         # matches configs/mise/macos.toml exactly
```

If any of those has grown, something was installed without being written down.
Either add it to the manifest or remove it — those are the only two options.
