#!/bin/bash
# Distro detection abstraction
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

# Skip on Fedora - uses dracut instead of mkinitcpio
if is_fedora; then
  exit 0
fi

echo "Temporarily disabling mkinitcpio hooks during installation..."

if [ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook ]; then
  sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled
fi
if [ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook ]; then
  sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled
fi
echo "mkinitcpio hooks disabled"
