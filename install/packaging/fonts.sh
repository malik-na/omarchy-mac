#!/bin/bash
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

# Omarchy logo in a font for Waybar use
mkdir -p ~/.local/share/fonts
cp ~/.local/share/omarchy/config/omarchy.ttf ~/.local/share/fonts/

# Ensure icon-capable font fallback exists on Fedora so Waybar module icons
# render at consistent size.
if is_fedora && ! rpm -q cascadia-mono-nf-fonts &>/dev/null; then
  sudo dnf install -y cascadia-mono-nf-fonts || true
fi

fc-cache
