#!/bin/bash
# Disable USB autosuspend to prevent peripheral disconnection issues

if [[ -f /proc/device-tree/compatible ]] && grep -qi "apple" /proc/device-tree/compatible 2>/dev/null; then
  echo "Skipping global USB autosuspend disable on Apple Silicon"
  exit 0
fi

if [[ ! -f /etc/modprobe.d/disable-usb-autosuspend.conf ]]; then
  echo "options usbcore autosuspend=-1" | sudo tee /etc/modprobe.d/disable-usb-autosuspend.conf
fi
