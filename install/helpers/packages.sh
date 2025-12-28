#!/bin/bash


# Omarchy package abstraction layer
source "${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}/helpers/distro.sh"

# Source Fedora helpers if needed
if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
  source "${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}/helpers/packages-fedora.sh"
fi

# Distro-agnostic package installed check
omarchy_package_installed() {
  local package="$1"
  if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
    fedora_package_installed "$package"
  else
    pacman -Qi "$package" >/dev/null 2>&1
  fi
}

# Determine whether any configured package manager can see the package metadata
omarchy_package_known_to_any_manager() {
  local package="$1"

  if pacman -Si "$package" >/dev/null 2>&1; then
    return 0
  fi

  if command -v yay >/dev/null 2>&1; then
    if yay -Si "$package" >/dev/null 2>&1; then
      return 0
    fi
  fi

  if command -v paru >/dev/null 2>&1; then
    if paru -Si "$package" >/dev/null 2>&1; then
      return 0
    fi
  fi

  return 1
}

# Internal helper: clone and build an AUR package without requiring a pre-existing AUR helper
omarchy_install_from_aur() {
  local aur_package="$1"
  local aur_url="https://aur.archlinux.org/${aur_package}.git"
  local workspace
  workspace=$(mktemp -d)

  if omarchy_package_installed "$aur_package"; then
    return 0
  fi

  # Ensure required build tooling is available before cloning
  sudo pacman -S --noconfirm --needed git base-devel

  if ! git clone "$aur_url" "$workspace/$aur_package"; then
    rm -rf "$workspace"
    return 1
  fi

  pushd "$workspace/$aur_package" >/dev/null || {
    rm -rf "$workspace"
    return 1
  }

  if ! makepkg -si --noconfirm --needed; then
    popd >/dev/null 2>&1 || true
    rm -rf "$workspace"
    return 1
  fi

  popd >/dev/null 2>&1 || true
  rm -rf "$workspace"
  return 0
}


# Distro-agnostic install
omarchy_install_package() {
  local package="$1"
  if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
    fedora_install_package "$package"
  else
    omarchy_install_package_with_fallback "$package"
  fi
}

# Distro-agnostic remove
omarchy_remove_package() {
  local package="$1"
  if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
    fedora_remove_package "$package"
  else
    sudo pacman -Rns --noconfirm "$package"
  fi
}

# Distro-agnostic update
omarchy_update_system() {
  if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
    fedora_update_system
  else
    sudo pacman -Syu --noconfirm
  fi
}

omarchy_install_package_with_fallback() {
  local package="$1"
  local managers=("pacman" "yay" "paru")
  local manager

  if omarchy_package_installed "$package"; then
    return 0
  fi

  for manager in "${managers[@]}"; do
    if omarchy_try_install_with_manager "$manager" "$package"; then
      return 0
    fi
  done

  return 1
}

# Ensure that a given AUR helper command is present, trying multiple package candidates
omarchy_ensure_aur_helper() {
  local helper_command="$1"
  shift
  local package_candidates=("$@")

  if command -v "$helper_command" >/dev/null 2>&1; then
    return 0
  fi

  echo "[Omarchy] Ensuring $helper_command is available..."

  for candidate in "${package_candidates[@]}"; do
    if omarchy_install_from_aur "$candidate"; then
      if command -v "$helper_command" >/dev/null 2>&1 || omarchy_package_installed "$candidate"; then
        echo "[Omarchy] Installed $helper_command via AUR package $candidate."
        return 0
      fi
    fi
  done

  echo "[Omarchy] Warning: Failed to install $helper_command." >&2
  return 1
}

# Public entry point: ensure yay and paru are installed before package installation begins
omarchy_setup_aur_helpers() {
  local failures=()

  omarchy_ensure_aur_helper "yay" "yay" "yay-bin" || failures+=("yay")
  omarchy_ensure_aur_helper "paru" "paru" "paru-bin" || failures+=("paru")

  if ((${#failures[@]} > 0)); then
    echo "[Omarchy] Warning: The following AUR helpers could not be set up: ${failures[*]}" >&2
  else
    echo "[Omarchy] yay and paru are ready for fallback installations."
  fi
}
