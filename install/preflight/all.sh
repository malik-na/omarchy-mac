#!/bin/bash
source $OMARCHY_INSTALL/preflight/guard.sh
source $OMARCHY_INSTALL/preflight/begin.sh
run_logged $OMARCHY_INSTALL/preflight/show-env.sh

# Detect ARM and configure environment early
arch=$(uname -m)
if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
  run_logged $OMARCHY_INSTALL/preflight/arm.sh
fi

run_logged $OMARCHY_INSTALL/preflight/arm-mirrors.sh
run_logged $OMARCHY_INSTALL/preflight/pacman.sh
run_logged $OMARCHY_INSTALL/preflight/migrations.sh
run_logged $OMARCHY_INSTALL/preflight/first-run-mode.sh
run_logged $OMARCHY_INSTALL/preflight/disable-mkinitcpio.sh
