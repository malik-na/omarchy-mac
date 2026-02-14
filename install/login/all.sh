#!/bin/bash
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"

run_logged "$OMARCHY_INSTALL/login/sddm.sh"
run_logged "$OMARCHY_INSTALL/login/default-keyring.sh"

run_logged "$OMARCHY_INSTALL/login/dracut.sh"
echo "[Omarchy] Fedora detected: configured SDDM login path and ran dracut integration."
