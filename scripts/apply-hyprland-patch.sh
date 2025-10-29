#!/usr/bin/env bash
set -euo pipefail

# apply-hyprland-patch.sh
# Build a PKGBUILD as an unprivileged user, then perform the required root
# operations in a single sudo session so the user is prompted for their
# password only once.
#
# Usage:
#   chmod +x scripts/apply-hyprland-patch.sh
#   ./scripts/apply-hyprland-patch.sh /path/to/patch-dir

PKGDIR="${1:-.}"
PKGDIR="$(realpath "$PKGDIR")"

if [ "$(id -u)" = "0" ]; then
  echo "Do NOT run this script as root. Run it as your regular user."
  exit 1
fi

if [ ! -d "$PKGDIR" ]; then
  echo "Directory not found: $PKGDIR"
  exit 1
fi

cd "$PKGDIR"
if [ ! -f PKGBUILD ]; then
  echo "No PKGBUILD found in $PKGDIR"
  exit 1
fi

echo "Building package in $PKGDIR (this runs as your user)..."
makepkg -f

# Find newest built package
pkgfile=$(ls -1t *.pkg.tar.* 2>/dev/null | head -n1 || true)
if [ -z "$pkgfile" ]; then
  echo "No package file produced by makepkg. Aborting."
  exit 1
fi

echo "Built package: $pkgfile"
echo
echo "I'll need sudo once to install the package and run system commands."
echo "You will be prompted for your password one time."

# Ask for password now and cache it
sudo -v

# Run all root actions in a single sudo bash -c so password is requested only once.
sudo bash -c '
set -euo pipefail
PKG_PATH="$1"
SUDO_USER_NAME="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"

echo "Installing package: $PKG_PATH"
pacman -U --noconfirm "$PKG_PATH"

echo "Ensuring llvm20 is installed..."
pacman -Sy --noconfirm llvm20

echo "Enabling and starting seatd.service..."
systemctl enable --now seatd.service

echo "Adding user \"$SUDO_USER_NAME\" to group 'seat'..."
usermod -aG seat "$SUDO_USER_NAME"

echo "Root-stage actions finished."
' -- "$PWD/$pkgfile"

echo
echo "Non-root build completed and root actions finished."
echo "Note: the new group membership will take effect after you log out and back in (or after a reboot)."

read -r -p "Reboot now? [y/N] " REBOOT_ANS
if [[ "$REBOOT_ANS" =~ ^[Yy]$ ]]; then
  echo "Rebooting..."
  sudo reboot
else
  echo "Done. Reboot skipped."
fi
