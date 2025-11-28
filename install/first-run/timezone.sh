#!/bin/bash
# First-run timezone setup
# Offers users a chance to configure timezone after installation

# Only run if we haven't configured timezone yet or if it's still UTC
current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")

if [[ "$current_tz" == "UTC" ]] || [[ -z "$current_tz" ]]; then
  # Check if we have internet connectivity
  if ping -c1 -W3 1.1.1.1 >/dev/null 2>&1; then
    notify-send "Timezone Setup" "Click to configure your timezone for accurate time display." -u normal -t 10000 -A "Configure Timezone=omarchy-cmd-tzupdate" -A "Skip=true"
  else
    # No internet - offer manual setup when connected
    notify-send "Timezone Setup" "Configure timezone when you have internet connection (right-click clock)." -u low -t 8000
  fi
fi
