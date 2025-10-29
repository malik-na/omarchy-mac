#!/bin/bash

# Architecture-specific package installation

# Check if running on ARM architecture
if [ -n "$OMARCHY_ARM" ]; then
  echo "Installing ARM-specific packages..."

  # Official ARM packages first (using yay to auto-select providers)
  if [ -s "$OMARCHY_INSTALL/omarchy-arm-official.packages" ]; then
    echo "Installing official ARM packages..."
    mapfile -t official_packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-arm-official.packages" | grep -v '^$' | sed 's/#.*$//' | sed 's/[[:space:]]*$//')
    if [ ${#official_packages[@]} -gt 0 ]; then
      sudo pacman -S --noconfirm --needed "${official_packages[@]}"
    fi
  fi

  # AUR ARM packages second (with GitHub fallback)
  if [ -s "$OMARCHY_INSTALL/omarchy-arm-aur.packages" ]; then
    echo "Installing AUR ARM packages..."
    mapfile -t aur_packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-arm-aur.packages" | grep -v '^$' | sed 's/#.*$//' | sed 's/[[:space:]]*$//')
    if [ ${#aur_packages[@]} -gt 0 ]; then
      "$OMARCHY_PATH/bin/omarchy-aur-install" --makepkg-flags="--needed" "${aur_packages[@]}"
    fi
  fi

  # Run ARM-specific installation scripts
  echo "Running ARM-specific installation scripts..."

  # Build Hyprland from source (ARM repos stuck at 0.49.0, need 0.51+ for GLES 3.0)
  source $OMARCHY_INSTALL/arm_install_scripts/hyprland.sh

  # Install Hyprland ecosystem packages (skipped in base.sh, now that hyprland is built)
  echo "Installing Hyprland ecosystem packages (hyprshade, aether)..."
  "$OMARCHY_PATH/bin/omarchy-aur-install" --makepkg-flags="--needed" hyprshade aether

  echo "ARM-specific package installation complete!"
else
  echo "Installing x86-specific packages..."

  # x86: Install packages from omarchy-x86.packages if it exists
  if [ -s "$OMARCHY_INSTALL/omarchy-x86.packages" ]; then
    mapfile -t packages < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-x86.packages" | grep -v '^$' | sed 's/#.*$//' | sed 's/[[:space:]]*$//')
    if [ ${#packages[@]} -gt 0 ]; then
      sudo pacman -S --noconfirm --needed "${packages[@]}"
    fi
  else
    echo "No x86-specific packages to install"
  fi
fi
