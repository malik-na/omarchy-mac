#!/bin/bash
set -e

echo "[Omarchy] Setting up console font for TTY..."

if ! command -v setfont &>/dev/null; then
  echo "[Omarchy] Installing kbd package..."
  sudo dnf install -y kbd
fi

echo "[Omarchy] Installing console-font.service..."
sudo cp ~/.local/share/omarchy/config/systemd/system/console-font.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable console-font.service
sudo systemctl start console-font.service

echo "[Omarchy] Console font service installed and enabled."
