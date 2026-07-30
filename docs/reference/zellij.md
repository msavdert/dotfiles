# Zellij Configuration & Integration Guide

This document describes the Zellij setup in this dotfiles repository, covering configuration choices, custom keybindings, and Zsh integrations.

---

## Overview

[Zellij](https://zellij.dev/) is a modern terminal multiplexer written in Rust. This configuration focuses on:
- **Ergonomics**: Quick pane/tab navigation using the `Alt` (Option) modifier key, bypassing the modal command layers.
- **Minimalism**: Hiding distracting frames (`pane_frames false`) and using a clean status line (`simplified_ui true`).
- **Persistence**: Reconnecting to existing sessions automatically (`attach_to_session true`).
- **Visuals**: A unified Catppuccin Mocha theme matches the overall aesthetics of the workspace.

---

## Configuration Settings (`config.kdl`)

The configuration file is located at `configs/zellij/config.kdl`. Key settings include:

| Setting | Value | Description |
| :--- | :--- | :--- |
| `theme` | `"catppuccin-mocha"` | Zellij's **built-in** catppuccin theme (see note) |
| `pane_frames` | `false` | Disables visual borders/frames around single panes |
| `default_layout` | `"compact"` | Uses a single-line status bar at the bottom |
| `on_force_close` | `"detach"` | Detaches the session instead of killing processes if closed unexpectedly |
| `simplified_ui` | `true` | Hides extraneous UI guides for a cleaner look |
| `copy_on_select` | `true` | Automatically copies selected text to the clipboard |
| `attach_to_session` | `true` | Auto-attaches to the last active session when starting Zellij |
| `scroll_buffer_size` | `30000` | Extends scrollback history limit to 30,000 lines |
| `styled_underlines` | `true` | Renders curl/colored underlines (e.g., LSP diagnostics) correctly |

**No `copy_command`.** Zellij runs inside the devbox container, where `pbcopy`
does not exist. Copying works over OSC 52 instead — the terminal itself carries
the text back to the macOS clipboard, through ssh and `docker exec`.

**No hand-written `themes { }` block.** Zellij has shipped catppuccin as a
built-in theme since 0.40, so declaring it by hand creates a second source of
truth. The block that used to live in `config.kdl` also had its palette wrong
(`white` was set to `#1e1e2e`, catppuccin's darkest base), which is why panes
looked washed out.

---

## Ergonomic Keybindings

We override keybindings in the `normal` mode to trigger common actions using the `Alt` (Option) key. This eliminates the need to press `Ctrl + o`/`Ctrl + p` before navigation.

### Pane Navigation & Resizing

| Keybind | Action | Description |
| :--- | :--- | :--- |
| `Alt + h` / `Alt + Left` | Move Focus Left | Switch to the pane on the left |
| `Alt + l` / `Alt + Right` | Move Focus Right | Switch to the pane on the right |
| `Alt + k` / `Alt + Up` | Move Focus Up | Switch to the pane above |
| `Alt + j` / `Alt + Down` | Move Focus Down | Switch to the pane below |
| `Alt + H` (Shift+h) | Resize Left | Expand the active pane to the left |
| `Alt + L` (Shift+l) | Resize Right | Expand the active pane to the right |
| `Alt + K` (Shift+k) | Resize Up | Expand the active pane upwards |
| `Alt + J` (Shift+j) | Resize Down | Expand the active pane downwards |

### Pane & Tab Management

| Keybind | Action | Description |
| :--- | :--- | :--- |
| `Alt + n` | New Pane | Open a new pane in the current tab |
| `Alt + x` | Close Pane | Close the active pane |
| `Alt + f` | Toggle Fullscreen | Maximize/minimize the active pane |
| `Alt + F` (Shift+f) | Toggle Floating | Toggle floating panes overlay |
| `Alt + t` | New Tab | Open a new tab |
| `Alt + [` | Previous Tab | Switch to the previous tab |
| `Alt + ]` | Next Tab | Switch to the next tab |

---

## Zsh Integration: Zellij Sessionizer

`zs`, defined in `configs/zsh/.zshrc`, combines `zoxide` (directory frecency),
`fzf` (picker) and Zellij's session manager into a one-key project switcher.

### How it works

1. `zs` opens an fzf picker over your most-visited directories from `zoxide`.
2. The selection becomes a session name (non-alphanumeric characters replaced
   with `_`).
3. If that session exists, it attaches. Otherwise it creates one, with the
   selected directory as the working directory.

```zsh
zs() {
    (( $+commands[zellij] && $+commands[zoxide] && $+commands[fzf] )) || {
        print -u2 "zs: needs zellij, zoxide and fzf"; return 1
    }
    local dir
    dir=$(zoxide query -l | fzf --height 40% --reverse --border --prompt='session > ')
    [[ -n $dir ]] || return 0
    local name="${${dir:t}//[^a-zA-Z0-9_-]/_}"
    zellij attach "$name" 2>/dev/null \
        || (cd "$dir" && zellij --session "$name")
}
```

The earlier version of this function used `zellij attach … options
--default-cwd "$dir"`, which sets the *default* cwd rather than the session's
working directory. `cd`-ing into the directory in a subshell before creating the
session is both simpler and actually correct.

---

## Where this runs

Zellij is a **devbox-only** tool. `configs/zellij/` is baked into the container
image and is deliberately *not* linked on macOS — see
[01-macos-setup.md](../01-macos-setup.md).

You normally never launch it by hand: the `Host dev` block in
`~/.ssh/config.local` runs `zellij attach -c main` as its `RemoteCommand`, so
`ssh dev` drops you straight into the persistent session. Use `zs` when you want
a *second*, project-scoped session alongside it.

**Detach with `Ctrl-o d`. Never `exit`** — that destroys the session and its
layout.
