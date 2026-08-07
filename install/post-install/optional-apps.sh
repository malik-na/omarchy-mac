#!/bin/bash
# Install optional proprietary/AUR apps (1Password, etc.)

# Only run on aarch64
if [ "$(uname -m)" != "aarch64" ]; then
    echo "Skipping optional apps: not aarch64 architecture"
    return 0
fi

# Install 1Password if the installer script exists
if [ -x "$OMARCHY_BIN/omarchy-install-1password" ]; then
    echo "Installing 1Password..."
    "$OMARCHY_BIN/omarchy-install-1password" || {
        echo "Warning: 1Password installation failed. You can install it manually later with:"
        echo "  omarchy-install-1password"
    }
fi

# Screen-share picker: the x86 hyprland-preview-share-picker (in omarchy-base.packages)
# has no ARM build, so xdg-desktop-portal-hyprland can't show a source chooser and
# browser screen/window sharing silently falls back to tab-only. Build the source
# package (its AUR PKGBUILD includes aarch64) so the themed picker + full-screen
# share work.
if ! command -v hyprland-preview-share-picker >/dev/null 2>&1; then
    echo "Installing hyprland-preview-share-picker (screen-share source picker)..."
    omarchy-pkg-aur-add hyprland-preview-share-picker-git || {
        echo "Warning: hyprland-preview-share-picker-git build failed; browser screen"
        echo "sharing may be tab-only. Retry: omarchy pkg aur add hyprland-preview-share-picker-git"
    }
fi
