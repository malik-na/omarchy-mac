#!/bin/bash
# Distro detection abstraction
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

if is_fedora; then
  exit 0
fi

if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  # ...existing code...
  sudo pacman -S --needed --noconfirm base-devel
  sudo cp -f ~/.local/share/omarchy/default/pacman/pacman.conf /etc/pacman.conf
  if [[ -x "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" ]]; then
    if [[ -n "${OMARCHY_FORCE_MIRROR_OVERWRITE:-}" ]]; then
      sudo "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" --force --backup || true
    else
      sudo "$OMARCHY_BIN/omarchy-refresh-pacman-mirrorlist" || true
    fi
  else
    sudo cp -f ~/.local/share/omarchy/default/pacman/mirrorlist /etc/pacman.d/mirrorlist
  fi
  sudo pacman-key --recv-keys 40DFB630FF42BCFFB047046CF0134EE680CAC571 --keyserver keys.openpgp.org
  sudo pacman-key --lsign-key 40DFB630FF42BCFFB047046CF0134EE680CAC571
  sudo pacman -Sy
  sudo pacman -S --noconfirm --needed omarchy-keyring
  sudo pacman -Syu --noconfirm
fi
