#!/usr/bin/env bash

set -euo pipefail

echo "Enable SDDM autologin with Hyprland session"

autologin_user="${SUDO_USER:-$USER}"
if [[ "$autologin_user" == "root" ]] || [[ -z "$autologin_user" ]]; then
  autologin_user="$(logname 2>/dev/null || true)"
fi
if [[ "$autologin_user" == "root" ]] || [[ -z "$autologin_user" ]]; then
  autologin_user="$(awk -F: '$3>=1000 && $3<65534 {print $1; exit}' /etc/passwd)"
fi

session_name="hyprland-uwsm"
if [[ ! -f /usr/share/wayland-sessions/hyprland-uwsm.desktop ]] && [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  session_name="hyprland"
fi

sudo mkdir -p /etc/sddm.conf.d
cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null
[Autologin]
User=$autologin_user
Session=$session_name
EOF

echo "Wrote /etc/sddm.conf.d/autologin.conf"
