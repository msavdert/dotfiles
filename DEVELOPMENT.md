# Development Guide

This guide explains how to maintain, modify, and expand these dotfiles.

## Project Architecture

The project follows a **No-Sudo** principle. Tools are installed as standalone binaries in user-space (`~/.local/bin`), and configurations are linked via symlinks.

### Core Components
- `bootstrap.sh`: The entry point. Handles `uv` installation, `uv`-managed Python environment, and repo fetching.
- `scripts/install-tools.sh`: The worker script for tool installation. Uses a unified `github_tool_install` helper.
- `scripts/link.sh`: Manages symlinks. Handles existing file backups automatically.
- `scripts/test-in-docker.sh`: Automated local testing script (Ubuntu 24.04).
- `bash/`, `git/`, `zellij/`, `nvim/`, `config/`: Source directories for configuration.

---

## Adding a New Tool

To add a new tool, follow these steps:

### 1. Update `scripts/install-tools.sh`

#### A. Define Filename and Extraction Functions
Most tools follow a standard GitHub Release pattern. Define how to find the binary and how to extract it.

```bash
# Example for a hypothetical tool 'mytool'
mytool_filename() {
    local version="$1" arch=$(uname -m)
    [ "$arch" = "x86_64" ] && arch="amd64" || arch="arm64"
    echo "mytool_${version}_linux_${arch}.tar.gz"
}

mytool_extract() {
    # extracted binary is usually in same folder
    tar -xzf "$1" -C "$BIN_DIR"
}
```

#### B. Register the Installer
```bash
install_mytool() {
    github_tool_install "owner/repo" "mytool" "mytool --version" mytool_filename mytool_extract
}
```

#### C. Add to Main Loop
Add `mytool` to the `tools` array in the `main()` function.

### 2. Register Shell Completion
Update `install_completion()` to generate completions for your tool if it supports it.

### 3. Add Aliases
Add shortcuts to `bash/.bash_aliases`.

---

## Adding a New Configuration (Symlink)

1. Create a directory (if complex) or a file in `config/` (for modern tools following XDG) or in the root for others.
2. Update `scripts/link.sh` to include a new `link_file` call:
   ```bash
   link_file "$DOTFILES_DIR/config/mytool/config" "$HOME/.config/mytool/config"
   ```

---

## Best Practices

### No-Sudo First
Always prefer downloading a pre-built binary. This ensures the script works on locked-down servers and minimal containers.

### Reliable Extraction via uv
We use `uv`-managed Python as the ultimate fallback for extracting ZIP and TBZ files. This ensures portability even on minimal Debian/Linux systems without `unzip` or `bzip2`.
- `extract_zip`: Uses `uv run python`.
- `extract_tar_bz2`: Uses `uv run python`.

### Local Customization & Secrets
Use `~/.bash_local` for your private environment variables (Git identity, OP tokens). This file is ignored by Git.

---

## Testing Changes

Before pushing, use the automated testing script:

```bash
bash scripts/test-in-docker.sh
```

This uses **OrbStack** (if available) to spin up a clean Ubuntu 24.04 container and runs the full bootstrap process.
