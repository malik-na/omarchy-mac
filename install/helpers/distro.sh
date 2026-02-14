#!/bin/bash

# Distro detection and environment setup
# Sets OMARCHY_DISTRO to 'fedora' when supported

detect_distro() {
  if [[ -f /etc/fedora-release ]]; then
    echo "fedora"
  else
    echo "unknown"
  fi
}

# Set OMARCHY_DISTRO if not already set
if [[ -z "${OMARCHY_DISTRO:-}" ]]; then
  export OMARCHY_DISTRO="$(detect_distro)"
fi

# Helper to check if running on Fedora
is_fedora() {
  [[ "$OMARCHY_DISTRO" == "fedora" ]]
}

# Helper kept for compatibility with existing scripts
is_arch() {
  return 1
}

# Check if running on Fedora Asahi specifically
is_fedora_asahi() {
  is_fedora && grep -q "asahi" /proc/version 2>/dev/null
}

# Helper kept for compatibility with existing scripts
is_arch_asahi() {
  return 1
}

echo "Distro: $OMARCHY_DISTRO"
