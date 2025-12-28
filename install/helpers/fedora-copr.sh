#!/bin/bash
# Enable required COPR repositories for Omarchy Fedora

# Only run on Fedora
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

if ! is_fedora; then
  exit 0
fi

# List of required COPR repos (from Research.md)
COPR_REPOS=(
  "solopasha/hyprland"
  "atim/starship"
  "atim/lazygit"
  "atim/eza"
  "pgdev/ghostty"
)

for repo in "${COPR_REPOS[@]}"; do
  echo "Enabling COPR repo: $repo"
  sudo dnf copr enable -y "$repo"
done

echo "COPR repositories enabled."
