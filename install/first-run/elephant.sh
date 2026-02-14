#!/bin/bash

if ! command -v elephant >/dev/null 2>&1; then
  echo "[WARN] elephant not installed; skipping first-run activation"
  exit 0
fi

elephant service enable
systemctl --user start elephant.service
