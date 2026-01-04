#!/bin/bash
# Disable shutting system down on power button to bind it to power menu afterwards

if [[ -f /etc/systemd/logind.conf ]]; then
  # Arch and systems with logind.conf
  sudo sed -i 's/.*HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
else
  # Fedora and systems using drop-in configs
  sudo mkdir -p /etc/systemd/logind.conf.d
  echo -e "[Login]\nHandlePowerKey=ignore" | sudo tee /etc/systemd/logind.conf.d/power-button.conf > /dev/null
fi
