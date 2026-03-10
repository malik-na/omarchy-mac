#!/bin/bash

set -euo pipefail

export OMARCHY_INSTALL_MODE="calamares"
export OMARCHY_NONINTERACTIVE=1
export OMARCHY_CHROOT_INSTALL=1

ENV_FILE="${1:-$(dirname "$0")/calamares/omarchy-install.env}"

if [[ -f $ENV_FILE ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

bash "$(dirname "$0")/install.sh"
