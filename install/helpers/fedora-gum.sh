#!/bin/bash
# Fedora: Install gum from GitHub release if not available in repos
set -e

GUM_VERSION="0.14.0"
GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_Linux_arm64.rpm"

if ! command -v gum &>/dev/null; then
  echo "[Omarchy] gum not found, downloading and installing from GitHub..."
  tmp_rpm="/tmp/gum_${GUM_VERSION}_Linux_arm64.rpm"
  curl -L "$GUM_URL" -o "$tmp_rpm"
  sudo dnf install -y "$tmp_rpm"
  rm -f "$tmp_rpm"
else
  echo "[Omarchy] gum already installed."
fi
