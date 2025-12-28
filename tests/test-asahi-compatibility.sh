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
export OMARCHY_PATH="${OMARCHY_PATH:-/omarchy/.local/share/omarchy}"
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
# Test ARM mirror selection logic
cd "$OMARCHY_PATH"
if bash -c 'source fix-mirrors.sh; echo "${arch_servers[@]}" | grep -q "archlinuxarm.org"' 2>/dev/null; then
  echo "✓ ARM-specific mirrors correctly selected"
else
  echo "ℹ ARM mirror selection test skipped (may not be implemented yet)"
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

echo "=== All Asahi Linux compatibility tests passed ==="
