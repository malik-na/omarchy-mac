#!/bin/bash
# Fedora: Install gum from GitHub release if not available in repos

GUM_VERSION="0.14.0"

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
  ARCH="x86_64"
fi

GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_Linux_${ARCH}.rpm"

if ! command -v gum &>/dev/null; then
  echo "[Omarchy] gum not found, downloading and installing from GitHub..."
  tmp_rpm="/tmp/gum_${GUM_VERSION}_Linux_${ARCH}.rpm"
  if curl -fL "$GUM_URL" -o "$tmp_rpm"; then
    sudo dnf install -y "$tmp_rpm"
    rm -f "$tmp_rpm"
  else
    echo "[WARN] Failed to download gum, installation UI may not work properly"
  fi
else
  echo "[Omarchy] gum already installed."
fi
