#!/bin/bash
source "$OMARCHY_INSTALL/helpers/chroot.sh"
source "$OMARCHY_INSTALL/helpers/presentation.sh"
source "$OMARCHY_INSTALL/helpers/errors.sh"
source "$OMARCHY_INSTALL/helpers/logging.sh"
# Distro detection abstraction (ensure OMARCHY_DISTRO is set)
source "$OMARCHY_INSTALL/helpers/distro.sh"
source "$OMARCHY_INSTALL/helpers/packages.sh"
source "$OMARCHY_INSTALL/helpers/packages-fedora.sh"
