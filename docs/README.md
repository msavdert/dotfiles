# Documentation

Written for the version of me who opens this repo in a year having forgotten
everything. Each document answers **what**, and more importantly **why** — the
alternatives that were considered and rejected are recorded too, so a future
change doesn't quietly re-introduce a problem that was already solved.

## Read in this order

| # | Document | Answers |
|---|----------|---------|
| 00 | [Architecture](00-architecture.md) | Why two tiers? Why an image instead of a bootstrap script? All decision records. |
| 01 | [macOS setup](01-macos-setup.md) | How the laptop is kept clean, and why brew *and* mise both exist. |
| 02 | [The devbox image](02-devbox-image.md) | What's inside the image, how it's built, how multi-arch works. |
| 03 | [VPS deployment](03-vps-deployment.md) | Getting from a bare Ubuntu VPS to `ssh dev` in about ten minutes. |
| 04 | [Daily usage](04-daily-usage.md) | The actual day-to-day: connecting, zellij, editing, moving code around. |
| 05 | [Secrets & 1Password](05-secrets.md) | How secrets are resolved, plus migration plans for Connect and Environments. |
| 06 | [Maintenance](06-maintenance.md) | Adding a tool, upgrading, rolling back, version policy. |
| 07 | [Troubleshooting](07-troubleshooting.md) | Symptom → cause → fix. |

## Reference

Background material that isn't part of the main narrative:

- [zellij](reference/zellij.md) — keybindings and configuration choices
- [mise custom backends](reference/mise-custom-backends.md) — installing tools
  from npm, cargo, GitHub releases, plain URLs

## The one-paragraph version

The Mac is a **thin client**: a terminal, 1Password, and about six CLI tools,
all declared in `macos/Brewfile` and enforced with `brew bundle --cleanup`, so
nothing can accumulate untracked. The real development environment is a
**container image** (`Dockerfile`) with every tool baked in at build time,
published to `ghcr.io` for amd64 and arm64 by GitHub Actions. It runs on a VPS
via `compose.yaml`; `ssh dev` drops straight into a persistent zellij session
inside it. Secrets are never exported into the shell — each command that needs
them is wrapped in `op run`, which resolves the `op://` references in
`configs/op-env/*.env` in a single request.
