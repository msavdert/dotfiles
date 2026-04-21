# Dev Environment

Mise-native development environment for Dokploy.

## Features
- **Mise** for tool management.
- **ttyd** for browser-based terminal.
- **Zsh** with Starship prompt.
- **Configs** managed in `configs/`.

## Deployment
This image is automatically published to `ghcr.io/msavdert/dotfiles` via GitHub Actions.

## Local Development
```bash
docker-compose up -d --build
docker exec -it dev-workspace zsh -l
```

### Initial Setup
Inside the container terminal, run:
```bash
mise run bootstrap
```
This will install all tools (neovim, node, etc.) defined in `mise.toml`.

