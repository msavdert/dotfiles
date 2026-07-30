# Managing Tools with Custom Backends in Mise

`mise` (formerly `rtx`) is an incredibly versatile environment and tool manager. While it comes with a default registry for standard languages (like Node.js, Python, Ruby), it also natively supports installing standalone binaries and packages via **Custom Backends**. This allows you to manage third-party tools directly in your `mise.toml` project standards.

## Supported Custom Backends

Mise leverages external package managers and distribution platforms to fetch tools. You can prefix tool names with these backends to install them. 

---

### 1. GitHub Releases (`github:`)
The most robust way to install compiled, standalone binaries. Mise will automatically resolve the latest release for your OS and architecture by scoring assets based on compatibility.

**Basic Usage:**
```toml
# Example: Installing Daniel Miessler's Fabric
"github:danielmiessler/fabric" = "latest"
```

**Advanced Tool Options:**
You can pass tool options for the `github:` backend in your `mise.toml`:
```toml
[tools."github:cli/cli"]
version = "latest"
asset_pattern = "gh_*_linux_x64.tar.gz" # Override auto-detection
version_prefix = "release-"             # Handle custom tag prefixes
strip_components = 1                    # Extract nested archives seamlessly
bin = "gh-cli"                          # Rename downloaded binary
```
*Source: [Mise GitHub Backend](https://mise.jdx.dev/dev-tools/backends/github.html)*

---

### 2. NPM Backend (`npm:`)
Install global JS packages isolated within your mise environment without polluting your system.

**Basic Usage:**
```toml
"npm:prettier" = "latest"
```

**Settings (`[settings]`):**
By default (`auto`), mise uses [aube](https://aube.en.dev/) if available, otherwise falling back to `npm`. You can override this to use **bun** or **pnpm** for much faster installations:
```toml
[settings]
npm.package_manager = "bun" # Choices: auto, npm, aube, bun, pnpm
```
*Source: [Mise NPM Backend](https://mise.jdx.dev/dev-tools/backends/npm.html)*

---

### 3. Pipx Backend (`pipx:`)
Designed for running Python CLIs in isolated virtual environments (like `black` or `poetry`), preventing dependency conflicts. It is NOT for installing standard Python libraries.

**Basic Usage:**
```toml
"pipx:black" = "24.3.0"
"pipx:git+https://github.com/psf/black.git@main" = "latest"
```

**Features & Settings:**
- By default, if `uv` is installed, mise will use `uvx` instead of `pipx` for blazingly fast installations. You can configure this via `pipx.uvx = true` in `[settings]`.
- You can specify extra components via tool options:
```toml
[tools."pipx:harlequin"]
version = "latest"
extras = "postgres,s3"
```
*Source: [Mise Pipx Backend](https://mise.jdx.dev/dev-tools/backends/pipx.html)*

---

### 4. Cargo Backend (`cargo:`)
Installs packages from Cargo Crates (crates.io) or Git repositories. 

**Basic Usage:**
```toml
"cargo:eza" = "latest"
"cargo:https://github.com/username/demo@tag:v1.0.0" = "latest"
```

**Features & Settings:**
- If you have `cargo-binstall` installed, mise will automatically use it to download precompiled binaries instead of compiling from source. Setting: `cargo.binstall = true`.
- Tool Options:
```toml
[tools."cargo:cargo-edit"]
version = "latest"
features = "add"
default-features = false
locked = true # Uses Cargo.lock
```
*Source: [Mise Cargo Backend](https://mise.jdx.dev/dev-tools/backends/cargo.html)*

---

### 5. Go Backend (`go:`)
Compile and install tools written in Go natively using `go install`.

**Basic Usage:**
```toml
"go:github.com/DarthSim/hivemind" = "latest"
```

**Tool Options:**
```toml
[tools."go:github.com/golang-migrate/migrate/v4/cmd/migrate"]
version = "latest"
tags = "postgres" # Passes -tags to go install
```
*Source: [Mise Go Backend](https://mise.jdx.dev/dev-tools/backends/go.html)*

---

## Other Backends

Mise natively supports several other powerful backends:
- **`aqua:`** - A declarative CLI version manager integration.
- **`asdf:`** / **`vfox:`** - For legacy plugin ecosystems.
- **`gem:`** - For Ruby Gems.
- **`spm:`** / **`conda:`** / **`dotnet:`** - Experimental backends for specialized environments.

*Full documentation is available at the [Mise Backends Directory](https://mise.jdx.dev/dev-tools/backends/).*
