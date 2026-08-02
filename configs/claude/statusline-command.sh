#!/usr/bin/env bash
# Claude Code statusLine, styled after ~/.config/starship.toml
# (no PS1 was found in ~/.zshrc; that shell uses starship instead).
# Mirrors starship's directory (blue) / git_branch (purple, "git: " prefix) /
# git_status (red) segments, plus the active Claude model.
set -euo pipefail

input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Shorten $HOME to ~, like a typical prompt.
dir=${dir/#$HOME/\~}

# ANSI colors, dimmed to match the terminal's dimmed color guidance.
BLUE=$'\033[2;34m'
PURPLE=$'\033[2;35m'
GRAY=$'\033[2;37m'
RESET=$'\033[0m'

branch=""
status=""
if git -C "$dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
        status="*"
    fi
fi

printf '%s%s%s' "$BLUE" "$dir" "$RESET"
if [ -n "$branch" ]; then
    printf ' %sgit: %s%s%s' "$PURPLE" "$branch" "$status" "$RESET"
fi
printf ' %s[%s]%s' "$GRAY" "$model" "$RESET"
