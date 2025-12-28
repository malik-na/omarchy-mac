#!/bin/bash
# Automatic ARM mirror setup for Omarchy installation
# This script automatically configures ARM mirrors if on ARM architecture


# Distro detection abstraction
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

# Only run on Arch ARM64
if is_fedora; then
  exit 0
fi
ARCH="$(uname -m)"
if [[ "$ARCH" != "aarch64" ]]; then
  [[ "${OMARCHY_DEBUG:-}" == "1" ]] && echo "[DEBUG] Not an ARM64 system (detected: $ARCH), skipping ARM mirror setup"
  exit 0
fi
if [[ ! -f /etc/arch-release ]]; then
  [[ "${OMARCHY_DEBUG:-}" == "1" ]] && echo "[DEBUG] Not an Arch Linux system, skipping ARM mirror setup"
  exit 0
fi

echo "[INFO] Detected ARM64 Arch Linux system, configuring optimal mirrors..."

# Source the ARM mirror helper
ARM_MIRROR_SCRIPT="$OMARCHY_INSTALL/helpers/set-arm-mirrors.sh"

if [[ ! -x "$ARM_MIRROR_SCRIPT" ]]; then
  echo "[WARN] ARM mirror helper script not found or not executable: $ARM_MIRROR_SCRIPT"
  exit 0
fi

# Auto-detect and setup with backup by default
# Use --test to verify connectivity, --backup for safety
"$ARM_MIRROR_SCRIPT" --auto --test --backup --verbose

if [[ $? -eq 0 ]]; then
  echo "[OK] ARM mirrors configured successfully"
else
  echo "[WARN] ARM mirror configuration completed with warnings"
fi
