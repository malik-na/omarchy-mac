#!/bin/bash

source "$OMARCHY_INSTALL/helpers/packages.sh"

# Ensure AUR helpers are set up before attempting any package installation fallbacks.
omarchy_setup_aur_helpers
