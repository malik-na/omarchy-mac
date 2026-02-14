#!/bin/bash

# Omarchy Fedora package abstraction layer
source "${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}/helpers/distro.sh"
source "${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}/helpers/packages-fedora.sh"

if ! is_fedora; then
  echo "[Omarchy] Unsupported distro for package helpers: $OMARCHY_DISTRO" >&2
  return 1 2>/dev/null || exit 1
fi

omarchy_package_installed() {
  local package="$1"
  fedora_package_installed "$package"
}

omarchy_package_known_to_any_manager() {
  local package="$1"
  dnf list --available "$package" >/dev/null 2>&1 || fedora_package_installed "$package"
}

omarchy_install_package() {
  local package="$1"
  fedora_install_package "$package"
}

omarchy_install_package_with_fallback() {
  local package="$1"
  fedora_install_package "$package"
}

omarchy_remove_package() {
  local package="$1"
  fedora_remove_package "$package"
}

omarchy_update_system() {
  fedora_update_system
}

# Kept for compatibility with legacy scripts; no-op on Fedora-only builds.
omarchy_setup_aur_helpers() {
  return 0
}
