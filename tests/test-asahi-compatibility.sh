#!/bin/bash
# Asahi Linux ARM64 Compatibility Test Script
# Tests ARM64 architecture compatibility and Asahi-specific features

set -e

echo "=== Running Asahi Linux Compatibility Test ==="
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"

# Test architecture detection
ARCH="$(uname -m)"
if [[ "$ARCH" == "aarch64" ]]; then
  echo "✓ ARM64 architecture detected correctly"
else
  echo "✗ Expected aarch64, got: $ARCH"
  exit 1
fi

# Set up environment variables if not already set
export OMARCHY_PATH="${OMARCHY_PATH:-$(pwd)}"
export OMARCHY_INSTALL="$OMARCHY_PATH/install"

echo "=== Testing fix-mirrors.sh ARM64 compatibility ==="
# Test if fix-mirrors.sh exists and can handle ARM64
if [[ -f "$OMARCHY_PATH/fix-mirrors.sh" ]]; then
  echo "✓ fix-mirrors.sh found"

  # Test dry-run mode for ARM64
  if cd "$OMARCHY_PATH" && bash fix-mirrors.sh --dry-run; then
    echo "✓ fix-mirrors.sh dry-run completed successfully"
  else
    echo "✗ fix-mirrors.sh dry-run failed"
    exit 1
  fi
else
  echo "✗ fix-mirrors.sh not found at $OMARCHY_PATH"
  exit 1
fi

echo "=== Testing architecture-specific mirror selection ==="
# Test ARM mirror selection logic and canonical defaults
if grep -q "mirror.archlinuxarm.org" "$OMARCHY_PATH/default/pacman/mirrorlist" && \
  grep -q "github.com/asahi-alarm/asahi-alarm/releases/download/\$arch" "$OMARCHY_PATH/default/pacman/mirrorlist.asahi-alarm"; then
  echo "✓ ARM and Asahi Alarm mirror defaults are present"
else
  echo "✗ Missing ARM or Asahi Alarm mirror defaults"
  exit 1
fi

echo "=== Testing Asahi hardware detection ==="
# Check for Apple Silicon hardware indicators
if [[ -f /proc/device-tree/compatible ]]; then
  echo "✓ Device tree detected (potential Apple Silicon hardware)"
  if grep -q "apple" /proc/device-tree/compatible 2>/dev/null; then
    echo "✓ Apple hardware detected in device tree"
  fi
else
  echo "ℹ No device tree found (running in container/VM)"
fi

echo "=== Testing guard.sh ARM64 support ==="
# Test guard script ARM64 support
GUARD_FILE="$OMARCHY_INSTALL/preflight/guard.sh"
if [[ -f "$GUARD_FILE" ]]; then
  if grep -q "aarch64\|arm64" "$GUARD_FILE"; then
    echo "✓ guard.sh includes ARM64 support"
  else
    echo "✗ guard.sh missing ARM64 support"
    exit 1
  fi
else
  echo "✗ guard.sh not found at $GUARD_FILE"
  exit 1
fi

echo "=== Testing installer pacman defaults ==="
if [[ -f "$OMARCHY_PATH/default/pacman/pacman.conf" ]]; then
  if grep -q "^Architecture = aarch64" "$OMARCHY_PATH/default/pacman/pacman.conf" && \
    grep -q "^\[asahi-alarm\]" "$OMARCHY_PATH/default/pacman/pacman.conf"; then
    echo "✓ Installer pacman defaults target Asahi Alarm on aarch64"
  else
    echo "✗ Installer pacman defaults are not Asahi Alarm specific"
    exit 1
  fi
else
  echo "✗ Installer pacman default file missing"
  exit 1
fi

echo "=== All Asahi Linux compatibility tests passed ==="
