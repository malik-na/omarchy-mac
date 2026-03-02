#!/bin/bash
# Install optional proprietary/AUR apps (1Password, etc.)

OMARCHY_PATH="${OMARCHY_PATH:-$HOME/.local/share/omarchy}"
OMARCHY_BIN="${OMARCHY_BIN:-$OMARCHY_PATH/bin}"

# Only run on aarch64
if [ "$(uname -m)" != "aarch64" ]; then
    echo "Skipping optional apps: not aarch64 architecture"
    exit 0
fi

# Install 1Password if the installer script exists
if [ -x "$OMARCHY_BIN/omarchy-install-1password" ]; then
    echo "Installing 1Password..."
    "$OMARCHY_BIN/omarchy-install-1password" || {
        echo "Warning: 1Password installation failed. You can install it manually later with:"
        echo "  omarchy-install-1password"
    }
fi
