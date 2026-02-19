#!/bin/bash
# First-run keyboard layout setup for Omarchy
# Provides interactive selection via gum if layout is unset or default (us)

KEYBOARD_LOG="/tmp/omarchy-keyboard.log"

log_debug() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$KEYBOARD_LOG"
  [[ "${OMARCHY_DEBUG:-}" == "1" ]] && echo "[DEBUG] $1" >&2
}

log_info() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$KEYBOARD_LOG"
  echo "[INFO] $1"
}

# Helper: set keyboard layout system-wide
set_keyboard_layout() {
  local layout="$1"

  if [[ -z "$layout" ]]; then
    log_debug "No layout provided to set_keyboard_layout"
    return 1
  fi

  log_info "Applying keyboard layout: $layout"

  sudo localectl set-x11-keymap "$layout"
  sudo localectl set-keymap "$layout" 2>/dev/null || true

  if grep -q "^KEYMAP=" /etc/vconsole.conf 2>/dev/null; then
    sudo sed -i "s/^KEYMAP=.*/KEYMAP=$layout/" /etc/vconsole.conf
  else
    echo "KEYMAP=$layout" | sudo tee -a /etc/vconsole.conf >/dev/null
  fi

  notify-send "Keyboard Layout" "Layout set to $layout" -u low -t 3000
  log_info "Keyboard layout successfully set to: $layout"
}

# Helper: interactive selection using gum
configure_keyboard_interactive() {
  if ! command -v gum >/dev/null 2>&1; then
    log_info "gum not available, skipping keyboard layout configuration"
    return 0
  fi

  notify-send "Keyboard Layout" "Configure your keyboard layout." -u normal -t 8000
  log_info "Starting interactive keyboard layout configuration"

  local layout_choice selected

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
    "Keep current")

  # If user pressed ESC or aborted
  [[ -z "$layout_choice" ]] && log_info "User aborted keyboard layout selection" && return 0

  selected=$(echo "$layout_choice" | awk '{print $1}')

  if [[ "$selected" == "Keep" ]]; then
    log_info "User chose to keep current layout"
    return 0
  fi

  set_keyboard_layout "$selected"
}

# Main logic
main() {
  log_info "Starting keyboard layout detection and configuration"

  local current_layout
  current_layout=$(localectl status | grep "X11 Layout" | awk '{print $3}' 2>/dev/null || echo "us")

  if [[ -z "$current_layout" || "$current_layout" == "us" || "$current_layout" == "(unset)" ]]; then
    log_info "Keyboard layout is unset or default ($current_layout), prompting user"
    configure_keyboard_interactive
  else
    log_info "Keyboard layout already configured: $current_layout"
  fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
