#!/bin/bash

# Soft abort: warn, but allow user to continue or skip with a clear message
abort() {
  echo -e "\e[31m[Omarchy] Requirement not met: $1\e[0m"
  echo
  gum confirm "Proceed anyway? (Not recommended. You may encounter issues and support may not be available.)" || {
    echo -e "\e[33m[Omarchy] Installation aborted. Please review the requirement above.\e[0m"
    echo -e "For help, contact @tiredkebab on X (Twitter)."
    exit 1
  }
  echo -e "\e[33m[Omarchy] Continuing at your own risk...\e[0m"
}

# Must be an Arch distro

if [[ ! -f /etc/arch-release ]]; then
  abort "Vanilla Arch (install on official Arch Linux only)"
fi

# Must not be an Arch derivative distro
for marker in /etc/cachyos-release /etc/eos-release /etc/garuda-release /etc/manjaro-release; do
  if [[ -f "$marker" ]]; then
    abort "Vanilla Arch (derivative detected: $(basename $marker))"
  fi
done

# Must not be running as root
if [ "$EUID" -eq 0 ]; then
  abort "Running as root (run as a regular user, not root)"
fi

# Must be x86_64 or ARM64 (aarch64)
ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
  abort "x86_64 or ARM64 (aarch64) CPU (detected: $ARCH)"
fi

# Must not have Gnome or KDE already install
if pacman -Qe gnome-shell &>/dev/null; then
  abort "Gnome is already installed. Omarchy requires a fresh, vanilla Arch install."
fi
if pacman -Qe plasma-desktop &>/dev/null; then
  abort "KDE Plasma is already installed. Omarchy requires a fresh, vanilla Arch install."
fi

# Cleared all guards
echo "Guards: OK"
