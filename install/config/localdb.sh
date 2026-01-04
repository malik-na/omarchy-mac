#!/bin/bash
# Update localdb so that locate will find everything installed
if command -v updatedb &>/dev/null; then
  sudo updatedb
else
  echo "[SKIP] updatedb not found (mlocate/plocate not installed)"
fi
