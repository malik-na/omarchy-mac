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


# Distro detection abstraction
source "${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}/helpers/distro.sh"

if ! is_fedora; then
  abort "Unsupported distro (Fedora Asahi Remix required)"
fi

ARCH="$(uname -m)"
if [[ "$ARCH" != "aarch64" ]]; then
  abort "Fedora Asahi Remix requires ARM64 (aarch64) hardware. Detected: $ARCH"
fi

if ! grep -q "asahi" /proc/version 2>/dev/null; then
  abort "Fedora Asahi Remix required (not detected)"
fi

# Must not be running as root
if [ "$EUID" -eq 0 ]; then
  abort "Running as root (run as a regular user, not root)"
fi


# Cleared all guards
echo "Guards: OK"
