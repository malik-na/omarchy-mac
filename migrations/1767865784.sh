#!/usr/bin/env bash
set -euo pipefail

echo "Ensure Chromium is able to start on first run after ISO 3.3.0 install"

rm -rf "$HOME/.config/chromium/SingletonLock"
