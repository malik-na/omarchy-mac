#!/bin/bash
# Detect keyboard layout from Fedora console config and apply to Hyprland.

set -euo pipefail

conf="/etc/vconsole.conf"
hyprconf="$HOME/.config/hypr/input.conf"

set_or_insert_hypr_kv() {
  local key="$1"
  local value="$2"

  if grep -q "^[[:space:]]*${key}[[:space:]]*=" "$hyprconf"; then
    sed -i "s|^[[:space:]]*${key}[[:space:]]*=.*|  ${key} = ${value}|" "$hyprconf"
  else
    sed -i "/^[[:space:]]*kb_options *=/i\  ${key} = ${value}" "$hyprconf"
  fi
}

layout=""
variant=""

if [[ -f "$conf" ]]; then
  if grep -q '^XKBLAYOUT=' "$conf"; then
    layout=$(grep '^XKBLAYOUT=' "$conf" | cut -d= -f2 | tr -d '"')
  elif grep -q '^KEYMAP=' "$conf"; then
    keymap=$(grep '^KEYMAP=' "$conf" | cut -d= -f2 | tr -d '"')
    layout="${keymap%%-*}"
  fi

  if grep -q '^XKBVARIANT=' "$conf"; then
    variant=$(grep '^XKBVARIANT=' "$conf" | cut -d= -f2 | tr -d '"')
  fi
fi

if [[ -z "$layout" ]]; then
  if command -v gum >/dev/null 2>&1; then
    layout=$(gum input --placeholder "Keyboard layout (e.g. us, de, dk)" --value "us")
  fi
fi

[[ -z "$layout" ]] && layout="us"

set_or_insert_hypr_kv "kb_layout" "$layout"

if [[ -n "$variant" ]]; then
  set_or_insert_hypr_kv "kb_variant" "$variant"
fi
