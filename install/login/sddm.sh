#!/bin/bash

# Ensure the Fedora login path is SDDM-only.
sudo systemctl disable --now omarchy-seamless-login.service >/dev/null 2>&1 || true
sudo rm -f /etc/systemd/system/omarchy-seamless-login.service
sudo rm -f /etc/systemd/system/plymouth-quit.service.d/wait-for-graphical.conf
sudo systemctl unmask plymouth-quit-wait.service >/dev/null 2>&1 || true
sudo systemctl daemon-reload

# Undo tty1 changes from legacy seamless-login setups.
sudo systemctl enable getty@tty1.service >/dev/null 2>&1 || true

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
