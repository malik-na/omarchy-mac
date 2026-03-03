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
  "technochip/Hyprland-aarch64"
  "atim/starship"
  "atim/lazygit"
  "pgdev/ghostty"
)

# Optional COPR repos (may not be available for all Fedora versions)
OPTIONAL_COPR_REPOS=(
  "solopasha/hyprland"
  "nclundell/fedora-extras"
  "erikreider/swayosd"
)

echo "Enabling required COPR repositories..."
for repo in "${COPR_REPOS[@]}"; do
  echo "Enabling COPR repo: $repo"
  if sudo dnf copr enable -y "$repo"; then
    echo "✓ Successfully enabled: $repo"
  else
    echo "✗ Failed to enable: $repo (required)"
    exit 1
  fi
done

echo "Enabling optional COPR repositories..."
for repo in "${OPTIONAL_COPR_REPOS[@]}"; do
  echo "Attempting to enable optional COPR repo: $repo"
  if sudo dnf copr enable -y "$repo" 2>/dev/null; then
    echo "✓ Successfully enabled: $repo"
  else
    echo "⚠ Skipping unavailable repo: $repo (optional)"
  fi
done

echo "COPR repositories enabled."

# -------------------------------------------------------------
# HYPRLAND REPOSITORY PROTECTION 
# Technochip must provide Hyprland core to keep Asahi compat.
# Solopasha is used only as fallback for utilities (e.g. satty).
# -------------------------------------------------------------
TECHNOCHIP_REPO_FILE="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:technochip:Hyprland-aarch64.repo"
SOLOPASHA_REPO_FILE="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:solopasha:hyprland.repo"

echo "Applying repo protections for Hyprland stability..."

if [[ -f "$SOLOPASHA_REPO_FILE" ]]; then
  # Remove any existing protections to recreate them clean
  sudo sed -i '/^priority=/d' "$SOLOPASHA_REPO_FILE"
  sudo sed -i '/^excludepkgs=/d' "$SOLOPASHA_REPO_FILE"
  
  # Inject protections: drop priority, and never pull core packages from here
  # NOTE: hyprland-qtutils is deliberately NOT excluded so we can fetch it here
  echo "priority=90" | sudo tee -a "$SOLOPASHA_REPO_FILE" >/dev/null
  echo "excludepkgs=hyprland hyprland-devel hyprlock hypridle hyprsunset hyprpicker hyprwire aquamarine hyprgraphics hyprutils hyprlang hyprcursor xdg-desktop-portal-hyprland uwsm" | sudo tee -a "$SOLOPASHA_REPO_FILE" >/dev/null
  echo "✓ Solopasha repo limits applied."
fi

if [[ -f "$TECHNOCHIP_REPO_FILE" ]]; then
  sudo sed -i '/^priority=/d' "$TECHNOCHIP_REPO_FILE"
  
  # Boost priority for the Asahi safe build
  echo "priority=10" | sudo tee -a "$TECHNOCHIP_REPO_FILE" >/dev/null
  echo "✓ Technochip repo priority applied."
fi
