#!/bin/bash
# Prompt for user identification (name and email) if not already set
# This is used for git configuration and XCompose shortcuts

read_install_value() {
  local value="$1"
  value="${value//$'\r'/}"
  printf '%s' "$value"
}

if [[ -n ${OMARCHY_USER_NAME:-} ]]; then
  OMARCHY_USER_NAME=$(read_install_value "$OMARCHY_USER_NAME")
  export OMARCHY_USER_NAME
fi

if [[ -n ${OMARCHY_USER_EMAIL:-} ]]; then
  OMARCHY_USER_EMAIL=$(read_install_value "$OMARCHY_USER_EMAIL")
  export OMARCHY_USER_EMAIL
fi

# Only prompt if not already set (e.g., by ISO configurator)
if [[ -z ${OMARCHY_USER_NAME:-} ]] && ! omarchy_install_is_noninteractive; then
  echo
  OMARCHY_USER_NAME=$(gum input --placeholder "Enter full name (optional, press ESC to skip)" --prompt "Name> " 2>/dev/null || echo "")
  export OMARCHY_USER_NAME
fi

if [[ -z ${OMARCHY_USER_EMAIL:-} ]] && ! omarchy_install_is_noninteractive; then
  OMARCHY_USER_EMAIL=$(gum input --placeholder "Enter email address (optional, press ESC to skip)" --prompt "Email> " 2>/dev/null || echo "")
  export OMARCHY_USER_EMAIL
fi

# Always return success even if user skipped
true
