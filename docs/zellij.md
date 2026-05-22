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
| `theme` | `"catppuccin-mocha"` | Applies the Catppuccin theme |
| `pane_frames` | `false` | Disables visual borders/frames around single panes |
| `default_layout` | `"compact"` | Uses a single-line status bar at the bottom |
| `on_force_close` | `"detach"` | Detaches the session instead of killing processes if closed unexpectedly |
| `simplified_ui` | `true` | Hides extraneous UI guides for a cleaner look |
| `copy_on_select` | `true` | Automatically copies selected text to the clipboard |
| `copy_command` | `"pbcopy"` | Direct integration with macOS system clipboard |
| `attach_to_session` | `true` | Auto-attaches to the last active session when starting Zellij |
| `scroll_buffer_size` | `30000` | Extends scrollback history limit to 30,000 lines |
| `styled_underlines` | `true` | Renders curl/colored underlines (e.g., LSP diagnostics) correctly |

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

To make project navigation seamless, a custom helper function `zs` is integrated into `configs/.zshrc`. It combines `zoxide` (directory history), `fzf` (fuzzy finder), and Zellij's session manager.

### How it works:
1. Running the `zs` command triggers a search UI populated with your most frequently visited directories via `zoxide`.
2. Selecting a directory creates a new Zellij session named after that folder (with periods converted to underscores).
3. If a session with that name already exists, Zellij attaches to it instead of spawning a new one.
4. The working directory for the session is set to the selected project folder automatically.

### Function Code (`.zshrc`):
```bash
# --- 10. Zellij Sessionizer ---
# Interactive Zellij session manager using fzf and zoxide
zs() {
    if ! command -v zellij >/dev/null; then
        echo "Error: zellij is not installed."
        return 1
    fi
    local dir
    dir=$(zoxide query -l | fzf --height 40% --reverse --border --prompt="📂 Zellij Session > ")
    if [ -n "$dir" ]; then
        local session_name
        session_name=$(basename "$dir" | tr '.' '_')
        # Attach to existing session or create a new one within selected directory
        zellij attach "$session_name" options --default-cwd "$dir" || zellij --session "$session_name" options --default-cwd "$dir"
    fi
}
```

---

## Installation & Setup

1. **Apply Symlinks**:
   Run the bootstrap symlink script to link your configuration to the correct paths:
   ```bash
   ./scripts/setup-symlinks.sh
   ```
   This will symlink:
   - `configs/zellij` to `~/.config/zellij`
   - `configs/.zshrc` to `~/.zshrc`

2. **Run Zellij**:
   Type `zellij` to start a default session, or use the interactive command `zs` to quickly select and launch/attach to project directories.
