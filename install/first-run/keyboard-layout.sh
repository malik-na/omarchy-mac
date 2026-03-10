#!/bin/bash
# First-run keyboard layout setup for Omarchy
# Provides interactive selection via gum if layout is unset or default (us)

KEYBOARD_LOG="/tmp/omarchy-keyboard.log"

get_current_layout() {
  local current_layout

  current_layout=$(localectl status 2>/dev/null | grep "X11 Layout" | awk '{print $3}')

  if [[ -z $current_layout || $current_layout == "(unset)" ]]; then
    current_layout=$(localectl status 2>/dev/null | grep "VC Keymap" | awk '{print $3}')
  fi

  [[ -n $current_layout ]] && printf '%s\n' "$current_layout" || printf 'us\n'
}

log_debug() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$KEYBOARD_LOG"
  [[ "${OMARCHY_DEBUG:-}" == "1" ]] && echo "[DEBUG] $1" >&2
}

log_info() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$KEYBOARD_LOG"
  echo "[INFO] $1"
}

resolve_x11_layout() {
  local selected="$1"
  local layout variant

  case "$selected" in
  uk)
    layout="gb"
    ;;
  de_CH)
    layout="ch"
    variant="de"
    ;;
  fr_CH)
    layout="ch"
    variant="fr"
    ;;
  fr-bepo)
    layout="fr"
    variant="bepo"
    ;;
  dvorak)
    layout="us"
    variant="dvorak"
    ;;
  colemak)
    layout="us"
    variant="colemak"
    ;;
  *)
    layout="$selected"
    ;;
  esac

  printf '%s|%s\n' "$layout" "$variant"
}

update_hypr_layout() {
  local layout="$1"
  local variant="$2"
  local hyprconf="$HOME/.config/hypr/input.conf"

  [[ -f "$hyprconf" ]] || return 0

  if grep -q "^[[:space:]]*#\?[[:space:]]*kb_layout[[:space:]]*=" "$hyprconf"; then
    sed -i "s|^[[:space:]]*#\?[[:space:]]*kb_layout[[:space:]]*=.*|  kb_layout = $layout|" "$hyprconf"
  else
    sed -i "/^[[:space:]]*kb_options *=/i\  kb_layout = $layout" "$hyprconf"
  fi

  sed -i "/^[[:space:]]*kb_variant[[:space:]]*=/d" "$hyprconf"

  if [[ -n $variant ]]; then
    sed -i "/^[[:space:]]*kb_options *=/i\  kb_variant = $variant" "$hyprconf"
  fi
}

# Helper: set keyboard layout system-wide
set_keyboard_layout() {
  local layout="$1"
  local resolved x11_layout x11_variant

  if [[ -z "$layout" ]]; then
    log_debug "No layout provided to set_keyboard_layout"
    return 1
  fi

  log_info "Applying keyboard layout: $layout"

  resolved=$(resolve_x11_layout "$layout")
  x11_layout=${resolved%%|*}
  x11_variant=${resolved#*|}

  if [[ -n $x11_variant ]]; then
    if ! sudo localectl set-x11-keymap "$x11_layout" "" "$x11_variant"; then
      notify-send "Keyboard Layout" "Failed to set layout: $layout" -u critical -t 5000
      log_info "Failed to set X11 keyboard layout: $layout ($x11_layout/$x11_variant)"
      return 1
    fi
  elif ! sudo localectl set-x11-keymap "$x11_layout"; then
    notify-send "Keyboard Layout" "Failed to set layout: $layout" -u critical -t 5000
    log_info "Failed to set X11 keyboard layout: $layout ($x11_layout)"
    return 1
  fi

  update_hypr_layout "$x11_layout" "$x11_variant"

  notify-send "Keyboard Layout" "Layout set to $layout" -u low -t 3000
  log_info "Keyboard layout successfully set to: $layout ($x11_layout${x11_variant:+/$x11_variant})"
}

# Helper: interactive selection using gum
configure_keyboard_interactive() {
  local current_layout="$1"

  if ! command -v gum >/dev/null 2>&1; then
    log_info "gum not available, skipping keyboard layout configuration"
    return 0
  fi

  notify-send "Keyboard Layout" "Configure your keyboard layout." -u normal -t 8000
  log_info "Starting interactive keyboard layout configuration"

  local layout_choice selected
  local keep_label="Keep current ($current_layout)"

  layout_choice=$(gum choose --header "Select your keyboard layout:" \
    "us - US English" \
    "uk - UK English" \
    "de - German" \
    "de_CH - Swiss German" \
    "at - Austrian German" \
    "fr - French" \
    "fr_CH - Swiss French" \
    "fr-bepo - French BÉPO" \
    "es - Spanish" \
    "it - Italian" \
    "pt - Portuguese" \
    "nl - Dutch" \
    "be - Belgian" \
    "dk - Danish" \
    "no - Norwegian" \
    "se - Swedish" \
    "fi - Finnish" \
    "is - Icelandic" \
    "pl - Polish" \
    "cz - Czech" \
    "sk - Slovak" \
    "hu - Hungarian" \
    "ro - Romanian" \
    "ru - Russian" \
    "ua - Ukrainian" \
    "tr - Turkish" \
    "gr - Greek" \
    "il - Hebrew" \
    "jp - Japanese" \
    "dvorak - Dvorak" \
    "colemak - Colemak" \
    "$keep_label")

  # If user pressed ESC or aborted
  [[ -z "$layout_choice" ]] && log_info "User aborted keyboard layout selection" && return 0

  selected=$(echo "$layout_choice" | awk '{print $1}')

  if [[ $selected == "Keep" ]]; then
    log_info "User chose to keep current layout"
    return 0
  fi

  set_keyboard_layout "$selected"
}

# Main logic
main() {
  local force_prompt=false

  if [[ ${1:-} == "--force" ]]; then
    force_prompt=true
  fi

  log_info "Starting keyboard layout detection and configuration"

  local current_layout
  current_layout=$(get_current_layout)

  if [[ $force_prompt == true ]]; then
    log_info "Force prompt requested for layout: $current_layout"
    configure_keyboard_interactive "$current_layout"
  elif [[ -z $current_layout || $current_layout == "us" || $current_layout == "(unset)" ]]; then
    log_info "Keyboard layout is unset or default ($current_layout), prompting user"
    configure_keyboard_interactive "$current_layout"
  else
    log_info "Keyboard layout already configured: $current_layout"
  fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
