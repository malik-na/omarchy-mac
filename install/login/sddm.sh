#!/bin/bash

sudo mkdir -p /etc/sddm.conf.d

# Setup SDDM login service
sudo mkdir -p /usr/local/share/wayland-sessions
sudo cp "$OMARCHY_PATH/default/wayland-sessions/omarchy.desktop" /usr/local/share/wayland-sessions/omarchy.desktop
sudo cp "$OMARCHY_PATH/default/sddm/hyprland.conf" /usr/share/sddm/hyprland.conf

sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/10-wayland.conf >/dev/null
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=start-hyprland -- --config /usr/share/sddm/hyprland.conf
EOF

if [[ ! -f /etc/sddm.conf.d/autologin.conf ]]; then
  cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$USER
Session=omarchy

[Theme]
Current=omarchy
EOF
else
  sudo sed -i 's/^Session=hyprland-uwsm$/Session=omarchy/' /etc/sddm.conf.d/autologin.conf
fi

# Prevent password-based SDDM logins from creating an encrypted login keyring
# (which conflicts with the passwordless Default_keyring used for auto-unlock)
if [[ -f /etc/pam.d/sddm ]]; then
  sudo sed -i '/-auth.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm
  sudo sed -i '/-password.*pam_gnome_keyring\.so/d' /etc/pam.d/sddm
fi

# Tear down seamless-login if present (fresh install used to enable both DMs).
# Mirrors migrations/1758487660_change_dm_to_sddm.sh — that body never runs on
# first install because preflight only marks migrations as applied.
if systemctl list-unit-files omarchy-seamless-login.service &>/dev/null ||
  [[ -f /etc/systemd/system/omarchy-seamless-login.service ]] ||
  [[ -x /usr/local/bin/seamless-login ]]; then
  echo "Disabling omarchy-seamless-login in favor of SDDM"
  sudo systemctl disable omarchy-seamless-login.service 2>/dev/null || true
  sudo systemctl unmask plymouth-quit-wait.service 2>/dev/null || true
  sudo systemctl enable getty@tty1.service 2>/dev/null || true
  sudo rm -f /usr/local/bin/seamless-login
  sudo rm -f /etc/systemd/system/plymouth-quit.service.d/wait-for-graphical.conf
  sudo rm -f /etc/systemd/system/omarchy-seamless-login.service
  sudo systemctl daemon-reload 2>/dev/null || true
fi

# Don't use chrootable here as --now will cause issues for manual installs
sudo systemctl enable sddm.service
