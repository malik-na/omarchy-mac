#!/bin/bash

set -euo pipefail

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  xdg-user-dirs-update --force
fi

if [[ -f "$HOME/.config/user-dirs.dirs" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/user-dirs.dirs"
fi

xdg_dirs=(
  "${XDG_DESKTOP_DIR:-$HOME/Desktop}"
  "${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
  "${XDG_TEMPLATES_DIR:-$HOME/Templates}"
  "${XDG_PUBLICSHARE_DIR:-$HOME/Public}"
  "${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
  "${XDG_MUSIC_DIR:-$HOME/Music}"
  "${XDG_PICTURES_DIR:-$HOME/Pictures}"
  "${XDG_VIDEOS_DIR:-$HOME/Videos}"
)

for dir in "${xdg_dirs[@]}"; do
  [[ -n "$dir" ]] && mkdir -p "$dir"
done
