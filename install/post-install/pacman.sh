#!/bin/bash
# Configure pacman
sudo cp -f ~/.local/share/omarchy/default/pacman/pacman.conf /etc/pacman.conf
# Use safe mirrorlist updater to avoid overwriting a user's mirrorlist
if [[ -x "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" ]]; then
  if [[ -n "${OMARCHY_FORCE_MIRROR_OVERWRITE:-}" ]]; then
    sudo "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" --force --backup || true
  else
    sudo "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" || true
  fi
else
  sudo cp -f ~/.local/share/omarchy/default/pacman/mirrorlist /etc/pacman.d/mirrorlist
fi

if lspci -nn | grep -q "106b:180[12]"; then
  cat <<EOF | sudo tee -a /etc/pacman.conf >/dev/null

[arch-mact2]
Server = https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release
SigLevel = Never
EOF
fi
