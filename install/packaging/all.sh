#!/bin/bash
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
run_logged "$OMARCHY_INSTALL/helpers/fedora-gum.sh"

run_logged $OMARCHY_INSTALL/packaging/base.sh
run_logged $OMARCHY_INSTALL/packaging/fonts.sh
run_logged $OMARCHY_INSTALL/packaging/nvim.sh
run_logged $OMARCHY_INSTALL/packaging/icons.sh
run_logged $OMARCHY_INSTALL/packaging/webapps.sh
run_logged $OMARCHY_INSTALL/packaging/tuis.sh

# Fedora manual installs (pip packages, flatpaks, etc.)
run_logged "$OMARCHY_INSTALL/helpers/fedora-manual.sh"
