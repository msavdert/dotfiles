# Development Guide

This guide explains how to maintain, modify, and expand these dotfiles.

## Project Architecture

The project follows a **No-Sudo** principle. Tools are installed as standalone binaries in user-space (`~/.local/bin`), and configurations are linked via symlinks.

### Core Components
- `bootstrap.sh`: The entry point. Handles dependency checks, `gh` CLI installation, and repo fetching.
- `scripts/install-tools.sh`: The worker script for tool installation. Downloads binaries from GitHub releases.
- `scripts/link.sh`: Manages symlinks. Handles existing file backups automatically.
- `bash/`, `git/`, `zellij/`: Configuration source directories.

---

## Adding a New Tool

To add a new tool (e.g., `bat`, `eza`, `fzf`), follow these steps:

### 1. Update `scripts/install-tools.sh`
Add a new `install_<tool>` function. Use the following template for GitHub-based tools:

```bash
install_mytool() {
    if command_exists mytool; then
        return 0
    fi

    log_step "Installing MyTool"
    local version arch filename url
    
    # Get latest version (safely)
    version=$(curl -fsSL https://api.github.com/repos/owner/repo/releases/latest | awk -F'"' '/tag_name/ {print $4; exit}' | sed 's/^v//')
    
    arch=$(uname -m)
    # Map architectures if needed
    [ "$arch" = "x86_64" ] && arch="amd64"
    
    # Construct URL (check the repo's release naming convention)
    filename="mytool_${version}_linux_${arch}.tar.gz"
    url="https://github.com/owner/repo/releases/download/v${version}/${filename}"
    
    curl -fsSL -L "$url" -o "/tmp/$filename"
    # Extract and move to $BIN_DIR
    tar -xzf "/tmp/$filename" -C "$BIN_DIR"
    chmod +x "$BIN_DIR/mytool"
    rm -f "/tmp/$filename"
}
```

### 2. Register in `main()`
Add your new function to the `main()` loop in `install-tools.sh`.

### 3. (Optional) Add Aliases
Add shortcuts to `bash/.bash_aliases`.

---

## Adding a New Configuration (Symlink)

1. Create a directory for your config (e.g., `fzf/`).
2. Add your config files there.
3. Update `scripts/link.sh` to include a new `link_file` call:
   ```bash
   link_file "$DOTFILES_DIR/mytool/config" "$HOME/.config/mytool/config"
   ```

---

## Best Practices

### No-Sudo First
Always prefer downloading a pre-built binary over using `apt`, `dnf`, or `brew` (unless on macOS where `brew` is standard). This ensures the script works on locked-down servers and minimal containers.

### Portable Extraction
Avoid relying on `unzip`. Use `tar` (standard) or use the `extract_zip` helper function in `install-tools.sh` which falls back to Python 3.

### Local Customization & Secrets
Use `~/.bash_local` for your private environment variables (Git identity, OP tokens). This file is ignored by Git and is the correct place for local-only overrides.

### Clean Output
Use `log_step`, `log`, and `log_warn` functions to keep the output consistent and professional.

---

## Testing Changes

Always test your changes in a clean environment before pushing:

### Docker (Linux)
```bash
# Start a fresh container
docker run -it --rm ubuntu:24.04 bash

# Inside the container
apt update && apt install -y curl tar python3
curl -fsSL https://raw.githubusercontent.com/your-username/dotfiles/main/bootstrap.sh | bash
source ~/.bashrc
```

### macOS
If you have OrbStack installed:
```bash
orb create ubuntu test-env
orb shell test-env
# Run bootstrap...
```
