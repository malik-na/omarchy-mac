#!/bin/bash
# Fedora-specific dracut integration for Omarchy
# This script is sourced by login/all.sh if Fedora is detected

set -e

# Ensure dracut is installed
if ! command -v dracut &>/dev/null; then
  echo "[Omarchy] dracut not found, installing..."
  sudo dnf install -y dracut
fi

# Regenerate all initramfs images for all installed kernels
for kernel in /lib/modules/*; do
  kver=$(basename "$kernel")
  echo "[Omarchy] Regenerating initramfs for kernel $kver with dracut..."
  sudo dracut --force "/boot/initramfs-$kver.img" "$kver"
done

echo "[Omarchy] dracut integration complete."
