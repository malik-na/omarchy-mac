#!/bin/bash
# Ensure iwd service will be started
if [[ -f /usr/lib/systemd/system/iwd.service ]] || [[ -f /etc/systemd/system/iwd.service ]]; then
  sudo systemctl enable iwd.service
else
  echo "[SKIP] iwd.service not available"
fi

# Prevent systemd-networkd-wait-online timeout on boot
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
