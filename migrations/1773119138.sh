echo "Repair battery monitor setup for laptops"

if omarchy-battery-present; then
  mkdir -p ~/.config/systemd/user

  cp "$OMARCHY_PATH/config/systemd/user/omarchy-battery-monitor.service" ~/.config/systemd/user/
  cp "$OMARCHY_PATH/config/systemd/user/omarchy-battery-monitor.timer" ~/.config/systemd/user/

  systemctl --user daemon-reload
  systemctl --user enable --now omarchy-battery-monitor.timer || true
fi
