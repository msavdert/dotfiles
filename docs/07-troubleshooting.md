# 07 — Troubleshooting

## `ssh dev` hangs or fails

```bash
ssh vps                                  # is the host itself reachable?
ssh vps 'docker ps'                      # is the container running?
ssh vps 'docker logs devbox --tail 50'
ssh -v dev 2>&1 | tail -30               # verbose ssh
```

A stale `ControlMaster` socket is a common cause after a network change — the
connection looks alive but isn't:

```bash
rm -f ~/.ssh/sockets/*
```

If `RemoteCommand` fails with "the input device is not a TTY", `RequestTTY yes`
is missing from the `Host dev` block.

## zellij session vanished

```bash
ssh vps 'docker exec -it -u dev devbox zellij ls'
```

Sessions live in `~/.local/state`, which **is** a persistent volume, so they
survive container recreation. What does *not* survive is the running processes
inside the panes — the layout comes back, your `npm run dev` does not.

If `zellij ls` is empty, `zellij attach -c main` creates a fresh one.

Killed a session by typing `exit` instead of detaching (`Ctrl-o d`)? It's gone.
That's what detaching is for.

## `op` fails inside the devbox

```bash
docker exec devbox printenv OP_SERVICE_ACCOUNT_TOKEN | head -c 8   # is it set?
docker exec devbox op whoami                                       # is it valid?
```

Common causes, in order of likelihood:

- `.env` next to `compose.yaml` is missing or wasn't picked up — compose reads
  `.env` from its **own** directory, not your shell's.
- The token was rotated in 1Password but not updated on the VPS.
- The service account lacks read access to the `dotfiles` vault.
- The vault/item/field name in `configs/op-env/*.env` changed. Verify:
  `op read "op://dotfiles/OpenRouter/generaltoken"`.

Changed `.env`? `docker compose up -d` — environment changes need the container
recreated, not restarted.

## `claude` says the API key is missing

The wrapper only exists if `op` is present *and* `~/.config/op-env` exists:

```bash
which claude          # should print a shell function, not a path
ls ~/.config/op-env/
```

If `which claude` shows a plain binary path, the guard in `.zshrc` didn't fire.
Test the underlying call directly:

```bash
op run --env-file=~/.config/op-env/ai.env -- env | grep ANTHROPIC
```

## Shell start-up is slow

```bash
time zsh -i -c exit
```

Measured in the image as built: **~44ms** steady state. The first shell after a
fresh image is ~340ms because it builds the completion cache — that's expected
and happens once.

To find the culprit, add `zmodload zsh/zprof` as the first line of `.zshrc` and
`zprof` as the last, then open a shell.

The usual causes are things this config deliberately avoids — if start-up is
slow, something reintroduced one of them:

- `op read` at start-up → use `op run` wrappers instead
  ([D4](00-architecture.md#d4--secrets-are-never-in-the-environment))
- `source <(tool completion zsh)` → use `mise run completions:regen`
  ([D5](00-architecture.md#d5--shell-start-up-does-no-work))
- a full `compinit` on every start → the cache check is in `.zshrc`; note that
  the widespread `[[ -n file(#qN.mh+24) ]]` idiom **silently always takes the
  slow branch**, because `[[ ]]` performs no filename generation. The working
  form expands the glob in an array assignment.

## Completions stopped working

```bash
ls ~/.local/share/zsh/completions/
mise run completions:regen
rm -f ~/.cache/zsh/zcompdump
exec zsh
```

## Colours or icons are wrong

Missing icons → install the Nerd Font and select it in your terminal (Ghostty:
`configs/ghostty/config` → `font-family = "JetBrainsMono Nerd Font"`):
`brew install --cask font-jetbrains-mono-nerd-font`.

Washed-out or wrong colours → check `echo $TERM`. This config deliberately does
**not** export `TERM`; the terminal reports what it is. If something upstream is
forcing `xterm-256color`, remove that instead of compensating for it.

Missing terminfo on the remote side:

```bash
infocmp -x | ssh vps tic -x -
```

## nvim clipboard doesn't work

Copy uses OSC 52 and should just work through ssh + docker + zellij. **Paste
into nvim uses `Cmd-V`** — most terminals refuse OSC 52 *reads* for security
reasons, so `"+p` won't pull from the macOS clipboard. That's the terminal, not
a misconfiguration.

Check which provider is active:

```vim
:echo g:clipboard
```

Empty inside the devbox means the remote-detection in
`configs/nvim/lua/config/options.lua` didn't fire — it looks for `$SSH_TTY`,
`$SSH_CONNECTION` or `/.dockerenv`.

## Image build fails on arm64 only

Some tools don't publish arm64 binaries. Find which one from the CI log, then
either drop it or make it conditional. Reproduce locally on the Mac (native
arm64):

```bash
docker build --platform linux/arm64 -t devbox-arm .
```

If the arm64 job never *starts*, the runner isn't available — `ubuntu-24.04-arm`
is free for public repos only. Fallback in
[02-devbox-image.md](02-devbox-image.md#building).

## macOS setup removed something I wanted

It's in `~/.dotfiles-backups/<timestamp>/` if it was a config file. If
`brew bundle cleanup` uninstalled a package, add it to `macos/Brewfile` and
re-run `./macos/setup.sh`.

Nothing is deleted without being backed up or being re-installable from a
manifest — that's the design.

## Everything is broken, start over

```bash
# devbox: keeps ~/work, history, ~/.kube
ssh vps 'cd ~/devbox && docker compose down && docker compose pull && docker compose up -d'

# devbox: keep nothing at all
ssh vps 'cd ~/devbox && docker compose down -v && docker compose up -d'

# macOS
cd ~/dotfiles && git pull && ./macos/setup.sh
```

The second one destroys `~/work`. Make sure it's pushed first.
