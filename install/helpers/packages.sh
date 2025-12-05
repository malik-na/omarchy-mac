#!/bin/bash

# Check if a package is already installed (covers repo and AUR packages)
omarchy_package_installed() {
  local package="$1"
  pacman -Qi "$package" >/dev/null 2>&1
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

omarchy_try_install_with_manager() {
  local manager="$1"
  local package="$2"

  case "$manager" in
    pacman)
      if ! pacman -Si "$package" >/dev/null 2>&1; then
        return 1
      fi
      sudo pacman -S --noconfirm --needed "$package"
      ;;
    yay)
      command -v yay >/dev/null 2>&1 || return 1
      yay -S --noconfirm --needed "$package"
      ;;
    paru)
      command -v paru >/dev/null 2>&1 || return 1
      paru -S --noconfirm --needed "$package"
      ;;
    *)
      return 1
      ;;
  esac
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
