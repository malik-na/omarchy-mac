#!/bin/bash
# Configure keyboard backlight brightness
# Sets keyboard backlight to 50% if available

# Ensure brightnessctl is installed
if ! command -v brightnessctl &>/dev/null; then
  echo "Installing brightnessctl..."
  sudo dnf install -y brightnessctl
fi

# Setup sudo-less control for brightnessctl
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/brightnessctl" | sudo tee /etc/sudoers.d/brightnessctl
sudo chmod 440 /etc/sudoers.d/brightnessctl

# Check if keyboard backlight device exists and set it
if brightnessctl --list 2>/dev/null | grep -q "kbd_backlight"; then
  echo "Setting keyboard backlight to 50%"
  sudo brightnessctl --device=kbd_backlight set 50%
else
  echo "No keyboard backlight device found, skipping configuration"
fi
