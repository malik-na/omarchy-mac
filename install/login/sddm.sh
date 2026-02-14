#!/bin/bash

sudo mkdir -p /etc/sddm.conf.d

SESSION_NAME="hyprland-uwsm"
if [[ ! -f /usr/share/wayland-sessions/hyprland-uwsm.desktop ]] && [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  SESSION_NAME="hyprland"
fi

if [ ! -f /etc/sddm.conf.d/autologin.conf ]; then
  cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$USER
Session=$SESSION_NAME

[Theme]
Current=breeze
EOF
fi

# Don't use chrootable here as --now will cause issues for manual installs
sudo systemctl enable sddm.service
