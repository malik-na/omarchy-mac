#!/bin/bash
# Ensure we use system python3 and not mise's python3
# This is Arch-specific - Fedora handles this differently

# Source distro detection if available
if [[ -f "${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}/helpers/distro.sh" ]]; then
  source "${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}/helpers/distro.sh"
fi

# Only run on Arch Linux
if [[ -f /etc/fedora-release ]]; then
  echo "[SKIP] powerprofilesctl shebang fix not needed on Fedora"
  exit 0
fi

if [[ -f /usr/bin/powerprofilesctl ]]; then
  sudo sed -i '/env python3/ c\#!/bin/python3' /usr/bin/powerprofilesctl
else
  echo "[SKIP] powerprofilesctl not found at /usr/bin/powerprofilesctl"
fi
