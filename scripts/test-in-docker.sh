#!/usr/bin/env bash
# Local Docker Testing Script for Dotfiles
# Usage: ./scripts/test-in-docker.sh

set -euo pipefail

# Path to docker if not in PATH (OrbStack specific)
DOCKER="/Users/melihsavdert/.orbstack/bin/docker"
if ! command -v docker >/dev/null 2>&1; then
    if [ -x "$DOCKER" ]; then
        alias docker="$DOCKER"
    else
        echo "Error: docker not found"
        exit 1
    fi
fi

CONTAINER_NAME="ubuntu24"
IMAGE="ghcr.io/msavdert/docker-systemd:ubuntu-24.04"

echo "==> Cleaning up old container..."
$DOCKER rm -f $CONTAINER_NAME >/dev/null 2>&1 || true

echo "==> Starting new container: $IMAGE"
$DOCKER run -d --name $CONTAINER_NAME \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --cgroupns=host \
  $IMAGE

# Helper to run commands as root in container
exec_root() {
    $DOCKER exec $CONTAINER_NAME bash -c "$1"
}

# Helper to run commands as user melih in container
exec_user() {
    $DOCKER exec -u melih -w /home/melih/dotfiles $CONTAINER_NAME bash -c "$1"
}

echo "==> Installing system dependencies..."
exec_root "apt update && apt install -y git curl bash-completion sudo"

echo "==> Creating user 'melih'..."
exec_root "useradd -m -s /bin/bash melih && echo 'melih ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"

echo "==> Copying current dotfiles to container..."
$DOCKER cp . $CONTAINER_NAME:/home/melih/dotfiles
exec_root "chown -R melih:melih /home/melih/dotfiles"

echo "==> Running bootstrap.sh in container..."
exec_user "bash bootstrap.sh"

echo "==> Verifying installations..."
exec_user "export PATH=\$HOME/.local/bin:\$PATH && gh --version && starship --version && zellij --version && nvim --version"

echo "==> TESTING COMPLETED SUCCESSFULLY!"
