#!/usr/bin/env bash

set -euo pipefail

echo "Ensure screenshot dependencies are installed"

if ! command -v satty >/dev/null 2>&1; then
  if dnf list --available satty >/dev/null 2>&1; then
    echo "Installing satty"
    omarchy-pkg-add satty
  else
    echo "[WARN] satty is unavailable in enabled repositories"
  fi
fi

if ! command -v wayfreeze >/dev/null 2>&1; then
  if dnf list --available wayfreeze >/dev/null 2>&1; then
    echo "Installing wayfreeze"
    omarchy-pkg-add wayfreeze
  elif dnf list --available wayfreeze-git >/dev/null 2>&1; then
    echo "Installing wayfreeze-git"
    omarchy-pkg-add wayfreeze-git
  else
    echo "[INFO] wayfreeze package not available; screenshot capture still works without screen freeze"
  fi
fi
