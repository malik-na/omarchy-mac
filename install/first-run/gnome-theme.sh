#!/bin/bash
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

if [[ -d /usr/share/icons/Yaru ]]; then
  gsettings set org.gnome.desktop.interface icon-theme "Yaru-blue"
fi

if [[ -d /usr/share/icons/Yaru ]]; then
  sudo gtk-update-icon-cache /usr/share/icons/Yaru
fi
