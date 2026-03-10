#!/bin/bash

set -euo pipefail

export OMARCHY_INSTALL_MODE="calamares"
export OMARCHY_NONINTERACTIVE=1
export OMARCHY_CHROOT_INSTALL=1

if [[ -n ${1:-} && -f $1 ]]; then
  # shellcheck disable=SC1090
  source "$1"
fi

bash "$(dirname "$0")/install.sh"
