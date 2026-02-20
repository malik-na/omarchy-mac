#!/bin/bash

# Set locale to en_US.UTF-8 for proper installation TUI support

echo "Setting up locale (en_US.UTF-8)..."

# Check if en_US.UTF-8 is already the current locale
if [[ "$(locale | grep LANG=en_US.UTF-8)" ]] && [[ "$(locale | grep LC_ALL=en_US.UTF-8 2>/dev/null || echo 'not_set')" != "not_set" ]]; then
  echo "Locale already set to en_US.UTF-8"
  return 0
fi

# Use sudo only when not running as root
if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

# Ensure en_US.UTF-8 locale is generated
if ! locale -a | grep -q "en_US.utf8\|en_US.UTF-8"; then
  echo "Generating en_US.UTF-8 locale..."

  # Uncomment en_US.UTF-8 in locale.gen if it's commented
  if grep -q "^#en_US.UTF-8" /etc/locale.gen 2>/dev/null; then
    ${SUDO:+$SUDO }sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
  elif ! grep -q "^en_US.UTF-8" /etc/locale.gen 2>/dev/null; then
    # Add en_US.UTF-8 if it doesn't exist at all
    echo "en_US.UTF-8 UTF-8" | ${SUDO:+$SUDO }tee -a /etc/locale.gen >/dev/null
  fi

  # Generate locales
  ${SUDO:+$SUDO }locale-gen >/dev/null 2>&1
fi

# Set system locale
echo "LANG=en_US.UTF-8" | ${SUDO:+$SUDO }tee /etc/locale.conf >/dev/null

# Export locale variables for current session
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

echo "Locale set to en_US.UTF-8"
