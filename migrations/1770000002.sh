#!/usr/bin/env bash
# Migration: Install 1Password on aarch64 systems
# The AUR package is broken for aarch64, so we use the official installer script

set -euo pipefail

STATE_DIR="$HOME/.local/state/omarchy/migrations"
STATE_FILE="$STATE_DIR/1770000002.sh"

# Only run on aarch64
if [ "$(uname -m)" != "aarch64" ]; then
    echo "Skipping 1Password installation: not aarch64 architecture"
    mkdir -p "$STATE_DIR"
    touch "$STATE_FILE"
    exit 0
fi

# Check if already installed
if command -v 1password >/dev/null 2>&1; then
    INSTALLED_VERSION=$(1password --version 2>/dev/null || echo "unknown")
    echo "1Password already installed (version: ${INSTALLED_VERSION})"
    mkdir -p "$STATE_DIR"
    touch "$STATE_FILE"
    exit 0
fi

echo "Installing 1Password on aarch64 system..."

# Run the installer script
if [ -x "$HOME/.local/share/omarchy/bin/omarchy-install-1password" ]; then
    "$HOME/.local/share/omarchy/bin/omarchy-install-1password" || {
        echo "Warning: 1Password installation failed. You can install it manually later with:"
        echo "  omarchy-install-1password"
    }
else
    echo "Warning: 1Password installer script not found. Skipping."
fi

# Mark migration as complete
mkdir -p "$STATE_DIR"
touch "$STATE_FILE"

echo "Migration complete."
