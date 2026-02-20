#!/bin/bash

set -euo pipefail

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  xdg-user-dirs-update
fi

if [[ -f "$HOME/.config/user-dirs.dirs" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/user-dirs.dirs"
fi

pictures_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}"
mkdir -p "$pictures_dir"
