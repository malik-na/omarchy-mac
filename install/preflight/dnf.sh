#!/bin/bash
if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  sudo dnf groupinstall -y "Development Tools"

  # Enable required COPR repositories (must be before package installation)
  source "${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}/helpers/fedora-copr.sh"

  # No need to configure mirrors for dnf (handled automatically)

  # Refresh all repos
  sudo dnf upgrade -y --refresh
fi
