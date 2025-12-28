#!/bin/bash

# Fedora-specific package management helpers for Omarchy

fedora_install_package() {
  sudo dnf install -y "$1"
}

fedora_package_installed() {
  rpm -q "$1" &>/dev/null
}

fedora_remove_package() {
  sudo dnf remove -y "$1"
}

fedora_update_system() {
  sudo dnf upgrade -y --refresh
}
