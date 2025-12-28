#!/bin/bash
# Distro detection abstraction
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

run_logged "$OMARCHY_INSTALL/login/plymouth.sh"

if is_arch; then
	run_logged "$OMARCHY_INSTALL/login/limine-snapper.sh"
	run_logged "$OMARCHY_INSTALL/login/enable-mkinitcpio.sh"
	run_logged "$OMARCHY_INSTALL/login/alt-bootloaders.sh"
elif is_fedora; then
	# TODO: Add Fedora-specific init/bootloader logic (e.g., dracut integration)
	echo "[Omarchy] Fedora detected: skipping Arch-specific login/init scripts."
fi
