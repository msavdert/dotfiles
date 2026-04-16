#!/usr/bin/env bash
# 1Password CLI helper
# Usage: ops [--item item-name] -- command
#        ops run [--item item-name] --command

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

usage() {
    cat << EOF
Usage: ops [OPTIONS] -- COMMAND

Run a command with secrets from 1Password.

Options:
    --item <name>    Get secrets from a specific item (default: dotfiles)
    --secret <name>  Get a specific secret value
    -h, --help       Show this help

Examples:
    ops -- echo \$MY_SECRET
    ops -- gh auth status
    ops --secret API_KEY -- echo \$API_KEY

Environment Variables (set in 1Password item):
    Keys must be stored as fields in the 1Password item.
EOF
}

# Get a secret from 1Password
get_secret() {
    local item="$1"
    local key="$2"
    op read "op://$item/$key" 2>/dev/null
}

# Get all secrets from an item and export as environment variables
export_secrets() {
    local item="$1"

    # Export each secret as an environment variable
    for secret in $(op read "op://$item" 2>/dev/null | grep -oP '(?<=op://)[^/]+/(?=[^/]+)' | sort -u); do
        continue  # Skip if no secrets
    done

    # Alternative: use op run to inject secrets
    # op run --no-interactive -- echo "\$SECRET_NAME"
}

# Sign in to 1Password
signin() {
    if ! op account list &>/dev/null || ! op whoami &>/dev/null; then
        echo "Signing in to 1Password..."
        eval "$(op signin)"
    fi
}

# Main
main() {
    local item_name="${OP_ITEM:-dotfiles}"
    local command=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --item)
                item_name="$2"
                shift 2
                ;;
            --secret)
                local secret_name="$2"
                shift 2
                signin
                op read "op://$item_name/$secret_name"
                exit 0
                ;;
            --)
                shift
                command=("$@")
                break
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done

    if [ ${#command[@]} -eq 0 ]; then
        echo "No command specified. Use -- to separate options from command."
        echo "Example: ops -- echo hello"
        exit 1
    fi

    # Sign in
    signin

    # Run command with 1Password
    # op run injections work by passing secrets as environment variables or templates
    op run -- "${command[@]}"
}

main "$@"