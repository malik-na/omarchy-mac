#!/usr/bin/env bash
# Migration: Install Widevine CDM for DRM streaming support (Netflix, etc.)
# This ensures existing Omarchy installations get DRM support

set -euo pipefail

echo "Checking Widevine CDM installation for DRM streaming support..."

# Only install if widevine package is available (asahi-alarm repo)
if pacman -Si widevine &>/dev/null; then
  if ! pacman -Qi widevine &>/dev/null; then
    echo "Installing widevine package for Netflix/DRM streaming support..."
    sudo pacman -S --noconfirm widevine
    echo "✓ Widevine CDM installed successfully"
  else
    echo "✓ Widevine already installed"
  fi
else
  echo "ℹ Widevine package not available in configured repositories (this is expected on non-aarch64 systems)"
fi

# Mark migration as complete
mkdir -p "$HOME/.local/state/omarchy/migrations"
touch "$HOME/.local/state/omarchy/migrations/1770000000.sh"

echo "Migration complete."
