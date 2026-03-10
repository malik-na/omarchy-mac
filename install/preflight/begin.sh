#!/bin/bash
clear_logo

if omarchy_install_is_noninteractive; then
  echo "[Omarchy] Installing..."
else
  gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Installing..."
fi

echo
start_install_log
