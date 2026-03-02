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

AUTOLOGIN_USER="${SUDO_USER:-$USER}"
if [[ "$AUTOLOGIN_USER" == "root" ]] || [[ -z "$AUTOLOGIN_USER" ]]; then
  AUTOLOGIN_USER="$(logname 2>/dev/null || true)"
fi
if [[ "$AUTOLOGIN_USER" == "root" ]] || [[ -z "$AUTOLOGIN_USER" ]]; then
  AUTOLOGIN_USER="$(awk -F: '$3>=1000 && $3<65534 {print $1; exit}' /etc/passwd)"
fi

SESSION_NAME="hyprland-uwsm"
if [[ ! -f /usr/share/wayland-sessions/hyprland-uwsm.desktop ]] && [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  SESSION_NAME="hyprland"
fi

cat <<EOF | sudo tee /etc/sddm.conf.d/10-omarchy-autologin.conf >/dev/null
[Autologin]
User=$AUTOLOGIN_USER
Session=$SESSION_NAME
EOF

cat <<EOF | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
[Theme]
Current=breeze
EOF

sudo systemctl set-default graphical.target

# Don't use chrootable here as --now will cause issues for manual installs
sudo systemctl enable sddm.service
