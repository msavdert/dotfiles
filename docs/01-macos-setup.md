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
4. Installs the four CLI tools from `configs/mise/macos.toml`.
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

Two files are read but never committed:

- `~/.zshrc.local` — machine-specific shell settings, sourced last.
- `~/.ssh/config.local` — real hostnames, per-host `ForwardAgent yes`, jump
  hosts. Included *first* by `configs/ssh/config`, and since OpenSSH takes the
  first value it sees for any keyword, anything here overrides the defaults.

This is where the `Host dev` block from
[03-vps-deployment.md](03-vps-deployment.md) goes.

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
brew list --formula | wc -l     # single digits
brew bundle cleanup --file=macos/Brewfile   # prints nothing
mise ls                         # four tools
```

If any of those has grown, something was installed without being written down.
Either add it to the manifest or remove it — those are the only two options.
