#!/bin/bash
# Configure pacman
sudo cp -f "$OMARCHY_PATH/default/pacman/pacman.conf" /etc/pacman.conf
sudo cp -f "$OMARCHY_PATH/default/pacman/mirrorlist.asahi-alarm" /etc/pacman.d/mirrorlist.asahi-alarm
# Use safe mirrorlist updater to avoid overwriting a user's mirrorlist
if [[ -x "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" ]]; then
  if [[ -n "${OMARCHY_FORCE_MIRROR_OVERWRITE:-}" ]]; then
    sudo "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" --force --backup || true
  else
    sudo "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" || true
  fi
else
  sudo cp -f "$OMARCHY_PATH/default/pacman/mirrorlist" /etc/pacman.d/mirrorlist
fi
