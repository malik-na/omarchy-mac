#!/bin/bash
# Fedora-specific dracut integration for Omarchy
# This script is sourced by login/all.sh if Fedora is detected

# Ensure dracut is installed
if ! command -v dracut &>/dev/null; then
  echo "[Omarchy] dracut not found, installing..."
  sudo dnf install -y dracut
fi

# Regenerate all initramfs images for all installed kernels
# Do NOT use set -e here — one kernel failure must not abort the rest
failed_kernels=()
success_kernels=()

for kernel in /lib/modules/*; do
  kver=$(basename "$kernel")
  echo "[Omarchy] Regenerating initramfs for kernel $kver with dracut..."
  if sudo dracut --force "/boot/initramfs-$kver.img" "$kver"; then
    success_kernels+=("$kver")
  else
    echo "[Omarchy] WARNING: dracut failed for $kver, continuing..."
    failed_kernels+=("$kver")
  fi
done

if (( ${#success_kernels[@]} > 0 )); then
  echo "[Omarchy] dracut integration complete for: ${success_kernels[*]}"
fi

if (( ${#failed_kernels[@]} > 0 )); then
  echo "[Omarchy] WARNING: dracut failed for kernels: ${failed_kernels[*]}"
  echo "[Omarchy] This may be a transient error. Run: sudo dracut --force on each failed kernel."
  # Non-zero exit only if ALL kernels failed
  if (( ${#success_kernels[@]} == 0 )); then
    exit 1
  fi
fi
