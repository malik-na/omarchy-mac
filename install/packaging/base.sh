#!/bin/bash
source "$OMARCHY_INSTALL/helpers/packages.sh"


# Select package list based on distro
if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
  package_file="$OMARCHY_INSTALL/omarchy-base.packages.fedora"
else
  package_file="$OMARCHY_INSTALL/omarchy-base.packages"
fi

core_packages=()
optional_packages=()
in_optional=0
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
  if [[ "$line" == "OPTIONAL:" ]]; then
    in_optional=1
    continue
  fi
  if ((in_optional)); then
    optional_packages+=("$line")
  else
    core_packages+=("$line")
  fi
done <"$package_file"

# Interactive selection for optional packages using gum
if command -v gum &>/dev/null && ((${#optional_packages[@]} > 0)); then
  echo "\e[34m[Omarchy] Select optional packages to install (use space to select, enter to confirm):\e[0m"
  selected_optional=$(printf '%s\n' "${optional_packages[@]}" | gum choose --no-limit --height 20)
  mapfile -t selected_optional_pkgs <<<"$selected_optional"
else
  selected_optional_pkgs=("${optional_packages[@]}")
fi

# Combine core and selected optional packages
packages=("${core_packages[@]}" "${selected_optional_pkgs[@]}")

# Pre-Install Compatibility Check
echo "\e[34m[Omarchy] Checking package availability...\e[0m"
unavailable_pkgs=()
for pkg in "${packages[@]}"; do
  if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
    if ! fedora_package_installed "$pkg" && ! dnf list --available "$pkg" &>/dev/null; then
      unavailable_pkgs+=("$pkg")
    fi
  else
    if ! omarchy_package_known_to_any_manager "$pkg"; then
      unavailable_pkgs+=("$pkg")
    fi
  fi
done
if ((${#unavailable_pkgs[@]} > 0)); then
  echo "\e[33m[Warning] The following packages were not found in pacman, yay, or paru metadata and may fail to install:\e[0m"
  for pkg in "${unavailable_pkgs[@]}"; do
    echo "  - $pkg"
  done
  echo
fi

# Install all base packages, skipping unavailable ones and listing failures at the end
failed_packages=()
for pkg in "${packages[@]}"; do
  if omarchy_package_installed "$pkg"; then
    echo "[SKIPPED] $pkg (already installed)"
    continue
  fi

  if omarchy_install_package "$pkg"; then
    echo "[OK] $pkg"
  else
    echo "[FAILED] $pkg"
    if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
      if dnf list --available "$pkg" &>/dev/null; then
        failed_packages+=("$pkg")
      else
        failed_packages+=("$pkg (not found in dnf)")
      fi
    else
      if omarchy_package_known_to_any_manager "$pkg"; then
        failed_packages+=("$pkg")
      else
        failed_packages+=("$pkg (not found in pacman/yay/paru)")
      fi
    fi
  fi
done

# Post-install summary and support
echo
if ((${#failed_packages[@]} > 0)); then
  echo "==============================="
  echo "The following packages could not be installed:"
  for pkg in "${failed_packages[@]}"; do
    echo "  - $pkg"
  done
  echo "==============================="
  echo "If you need help or want to request support for missing packages, contact @tiredkebab on X (Twitter)."
else
  echo "\e[32mAll packages installed successfully!\e[0m"
fi

echo
echo "[Omarchy] Installation complete. For troubleshooting, see the install log. For support, contact @tiredkebab on X (Twitter)."
