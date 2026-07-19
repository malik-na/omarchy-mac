#!/bin/bash
# Use the full Apple Silicon (Asahi) display height, including the strip beside
# the notch, so the top of the screen is usable for the Omarchy bar. Without
# this, Asahi crops the display below the notch. Only applies where the appledrm
# display driver exists (Apple Silicon); a no-op on T2 Intel Macs and non-Macs.
if modinfo appledrm &>/dev/null && [[ ! -f /etc/modprobe.d/asahi-notch.conf ]]; then
  echo "Enabling Asahi notch area (full display height) for the Omarchy bar"
  echo "options appledrm show_notch=1" | sudo tee /etc/modprobe.d/asahi-notch.conf >/dev/null
fi
