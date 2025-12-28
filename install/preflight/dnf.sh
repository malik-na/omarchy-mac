#!/bin/bash
if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  # Install build tools
  sudo dnf groupinstall -y "Development Tools"

  # No need to configure mirrors for dnf (handled automatically)

  # Refresh all repos
  sudo dnf upgrade -y --refresh
fi
