#!/bin/bash
if omarchy-battery-present; then
  # This computer runs on a battery
  powerprofilesctl set balanced || true

  # Enable battery monitoring timer for low battery notifications
  systemctl --user enable --now omarchy-battery-monitor.timer
else
  powerprofilesctl set performance || true
fi
