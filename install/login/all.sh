#!/bin/bash
# Distro detection abstraction
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

run_logged "$OMARCHY_INSTALL/login/plymouth.sh"
run_logged "$OMARCHY_INSTALL/login/sddm.sh"
run_logged "$OMARCHY_INSTALL/login/default-keyring.sh"

if is_arch; then
	run_logged "$OMARCHY_INSTALL/login/limine-snapper.sh"
	run_logged "$OMARCHY_INSTALL/login/enable-mkinitcpio.sh"
	run_logged "$OMARCHY_INSTALL/login/alt-bootloaders.sh"
elif is_fedora; then
	run_logged "$OMARCHY_INSTALL/login/dracut.sh"
	echo "[Omarchy] Fedora detected: ran dracut integration."
fi
