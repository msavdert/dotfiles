# 04 — Daily usage

## Starting work

```bash
ssh dev
```

That's it. You land in the container, attached to a zellij session named `main`
that has been running since the last time — same panes, same working
directories, same long-running processes.

Close the laptop, open it tomorrow, `ssh dev` again: everything is where you
left it. The session lives on the VPS; the terminal on the Mac is just a window
onto it.

## zellij

Detach with `Ctrl-o d`. **Never `exit`** — that kills the session and you lose
the layout. Detaching is what makes the whole setup persistent.

Alt-key navigation is bound directly in normal mode, so no modal prefix is
needed:

| Keys | Action |
|---|---|
| `Alt h/j/k/l` or `Alt ←↓↑→` | move focus between panes |
| `Alt H/J/K/L` | resize the focused pane |
| `Alt n` / `Alt x` | new pane / close pane |
| `Alt f` / `Alt F` | fullscreen / floating panes |
| `Alt t` | new tab |
| `Alt [` / `Alt ]` | previous / next tab |
| `Ctrl-o d` | **detach** |

Full details: [reference/zellij.md](reference/zellij.md).

### Multiple projects

`zs` opens a picker over zoxide's frecency list and attaches to (or creates) a
zellij session named after the directory:

```bash
zs        # pick a directory → session
```

One session per project keeps contexts from bleeding into each other. Switch
between them with `zellij attach <name>`, or `zellij ls` to see what exists.

## Editing

`nvim` (or `v`) inside the devbox. LazyVim with plugins baked into the image, so
the first launch is instant and works offline.

Clipboard: yanks go through **OSC 52**, which routes the text over the terminal
protocol itself — through ssh, through docker exec, through zellij — and into
the macOS clipboard. Nothing to configure.

The catch: OSC 52 *paste* (reading the system clipboard) is refused by most
terminals for security reasons. Use `Cmd-V`, which sends the text as keystrokes
and always works.

## Secrets

Wrapped commands resolve their own secrets. Just run them:

```bash
claude          # ANTHROPIC_* injected by op run, one request
kilocode
```

For anything else:

```bash
opwith ai   <command>    # injects configs/op-env/ai.env
opwith git  <command>    # injects configs/op-env/git.env
op read "op://dotfiles/GitHub/admintoken"    # one-off
```

Nothing is exported into the shell — `env | grep -i token` should be empty. See
[05-secrets.md](05-secrets.md).

## Git

`~/.gitconfig` resolves GitHub HTTPS credentials straight from 1Password
(`op://dotfiles/GitHub/admintoken`), not through `gh auth login`'s OAuth
session. No bootstrap step, no token in the environment, no SSH key inside
the container - and it behaves identically in a fresh container, a rebuilt
devbox image, or a non-interactive AI-agent shell (those never source
`~/.zshrc`, so the `opwith` wrapper isn't available to them either).

## Kubernetes

```bash
mise run kube:homelab    # pulls kubeconfig + talosconfig from 1Password
k get nodes              # k = kubectl
k9s
```

`~/.kube` is a persistent volume, so this survives container recreation. Re-run
it when credentials rotate.

Aliases: `k`, `kg`, `kgp`, `kgs`, `kgd`, `kgn`, `kd`, `kl`, `klf`, `kex`, `kns`,
`kctx` — all defined in `configs/zsh/.zshrc`.

## Moving files

The devbox is `docker exec`-only, so `scp` won't reach it directly.

```bash
# Mac → devbox
ssh vps 'docker cp - devbox:/home/dev/work' < <(tar cf - somedir)

# devbox → Mac
ssh vps 'docker exec devbox tar cf - -C /home/dev/work somedir' | tar xf -
```

In practice you rarely need this: push to git from one side and pull from the
other. If you find yourself copying files often, that's the argument for
Tailscale (real `scp`/`rsync` straight to the container).

## Tool names

Modern tools keep their own names — `grep` is `grep`, `rg` is `rg`. Pasted
commands from the internet behave exactly as their author intended.

| Alias | Runs |
|---|---|
| `ls` `ll` `la` `lt` | `eza` variants (`lt` = tree) |
| `bcat` | `bat --style=plain` |
| `duh` | `dust` |
| `pingg` | `gping` |
| `v` `vim` | `nvim` |

Why not `alias grep='rg'`:
[D8](00-architecture.md#d8--modern-cli-tools-do-not-shadow-posix-names).

## Fresh start

The container is disposable — resetting is normal, not an emergency:

```bash
ssh vps 'cd ~/devbox && docker compose down && docker compose up -d'
```

`~/work`, shell history and `~/.kube` survive. Everything else comes back from
the image exactly as it was.
