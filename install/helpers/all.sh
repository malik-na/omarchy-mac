#!/bin/bash
source "$OMARCHY_INSTALL/helpers/chroot.sh"
source "$OMARCHY_INSTALL/helpers/presentation.sh"
source "$OMARCHY_INSTALL/helpers/errors.sh"
source "$OMARCHY_INSTALL/helpers/logging.sh"
# Distro detection abstraction (ensure OMARCHY_DISTRO is set)
source "$OMARCHY_INSTALL/helpers/distro.sh"
source "$OMARCHY_INSTALL/helpers/packages.sh"
# Source Fedora helpers if needed
if [[ "$OMARCHY_DISTRO" == "fedora" ]]; then
	source "$OMARCHY_INSTALL/helpers/packages-fedora.sh"
fi
# Note: set-arm-mirrors.sh is executable script, not sourced
