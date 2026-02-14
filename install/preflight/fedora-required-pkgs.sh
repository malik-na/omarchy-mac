#!/bin/bash

required_pkgs=(
  hyprland
  waybar
  mako
  swaybg
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  xdg-terminal-exec
  lxpolkit
)

missing=()
for pkg in "${required_pkgs[@]}"; do
  if ! rpm -q "$pkg" >/dev/null 2>&1 && ! dnf list --available "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg")
  fi
done

if ((${#missing[@]} > 0)); then
  echo "[ERROR] Required Fedora packages are unavailable in enabled repositories:"
  for pkg in "${missing[@]}"; do
    echo "  - $pkg"
  done
  echo "Enable the required COPR repositories or adjust package mappings before continuing."
  exit 1
fi

echo "Required Fedora runtime packages are available."
