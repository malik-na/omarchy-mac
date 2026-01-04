#!/bin/bash
# Distro detection abstraction
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

if is_arch; then
	run_logged $OMARCHY_INSTALL/packaging/aur-helpers.sh
fi

if is_fedora; then
	run_logged "$OMARCHY_INSTALL/helpers/fedora-gum.sh"
fi

run_logged $OMARCHY_INSTALL/packaging/base.sh
run_logged $OMARCHY_INSTALL/packaging/fonts.sh
run_logged $OMARCHY_INSTALL/packaging/nvim.sh
run_logged $OMARCHY_INSTALL/packaging/icons.sh
run_logged $OMARCHY_INSTALL/packaging/webapps.sh
run_logged $OMARCHY_INSTALL/packaging/tuis.sh

# Fedora manual installs (pip packages, flatpaks, etc.)
if is_fedora; then
	run_logged "$OMARCHY_INSTALL/helpers/fedora-manual.sh"
fi
