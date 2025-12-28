#!/bin/bash

# Distro detection and environment setup
# Sets OMARCHY_DISTRO to 'arch' or 'fedora'

detect_distro() {
  if [[ -f /etc/fedora-release ]]; then
    echo "fedora"
  elif [[ -f /etc/arch-release ]]; then
    echo "arch"
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

# Helper to check if running on Arch
is_arch() {
  [[ "$OMARCHY_DISTRO" == "arch" ]]
}

# Check if running on Fedora Asahi specifically
is_fedora_asahi() {
  is_fedora && grep -q "asahi" /proc/version 2>/dev/null
}

# Check if running on Arch Asahi (Asahi Alarm)
is_arch_asahi() {
  is_arch && grep -q "asahi" /proc/version 2>/dev/null
}

echo "Distro: $OMARCHY_DISTRO"
