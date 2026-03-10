#!/bin/bash
# Setup passwordless sudo for installation scripts to prevent multiple password prompts
# This sudoers rule will be automatically removed after installation completes

install_user="${OMARCHY_INSTALL_USER:-$USER}"

if [[ -z $install_user ]]; then
  echo "[Omarchy] Error: install user not set for passwordless installer setup" >&2
  exit 1
fi

sudo tee /etc/sudoers.d/99-omarchy-installer >/dev/null <<EOF
# Temporary sudoers rule for Omarchy installation
# This file is automatically removed after installation
Cmnd_Alias INSTALLER_CLEANUP = /bin/rm -f /etc/sudoers.d/99-omarchy-installer
$install_user ALL=(ALL) NOPASSWD: ALL
EOF

# Set proper permissions for sudoers file
sudo chmod 440 /etc/sudoers.d/99-omarchy-installer
