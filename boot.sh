#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export OMARCHY_ONLINE_INSTALL=true

ansi_art='                 ▄▄▄                                                   
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄ 
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀ 
                                       ███   █▀                                  '

clear
echo -e "\n$ansi_art\n"

# Validate sudo access and refresh timestamp to minimize password prompts
echo "🔐 Omarchy Mac Installation requires administrator access..."
if ! sudo -v; then
  echo "❌ Error: sudo access required. Please run with proper permissions."
  exit 1
fi

# Keep sudo alive during bootstrap
keep_sudo_alive() {
  while true; do
    sudo -v
    sleep 50
  done
}

keep_sudo_alive &
SUDO_KEEPALIVE_PID=$!

# Cleanup on exit
trap 'sudo -k; kill ${SUDO_KEEPALIVE_PID:-} 2>/dev/null' EXIT INT TERM

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to malik-na/omarchy-mac
OMARCHY_REPO="${OMARCHY_REPO:-malik-na/omarchy-mac}"

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git"
rm -rf ~/.local/share/omarchy/
git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

# Use custom branch if instructed, otherwise default to main
OMARCHY_REF="${OMARCHY_REF:-main}"
if [[ $OMARCHY_REF != "main" ]]; then
  echo -e "\e[32mUsing branch: $OMARCHY_REF\e[0m"
  cd ~/.local/share/omarchy
  git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
  cd -
fi

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy/install.sh
