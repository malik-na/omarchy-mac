#!/usr/bin/env bash
#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

# Uncomment en_US.UTF-8 in /etc/locale.gen
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen

# Run locale-gen
locale-gen

# Check and update /etc/locale.conf
if grep -q "LANG=en_US.UTF-8" /etc/locale.conf; then
  echo "LANG=en_US.UTF-8 is already set in /etc/locale.conf"
else
  echo "LANG=en_US.UTF-8" >/etc/locale.conf
  echo "Updated /etc/locale.conf with LANG=en_US.UTF-8"
fi

# Run locale command
locale

# Reboot system
echo "Rebooting system..."
reboot
