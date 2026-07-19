#!/bin/bash
# Enhanced timezone detection and configuration
# Provides multiple detection methods and user choice during installation

TIMEZONE_LOG="/tmp/omarchy-timezone.log"

log_debug() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$TIMEZONE_LOG"
  [[ "${OMARCHY_DEBUG:-}" == "1" ]] && echo "[DEBUG] $1" >&2
}

log_info() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$TIMEZONE_LOG"
  echo "[INFO] $1"
}

# Method 1: IP-based geolocation detection using tzupdate
detect_timezone_ip() {
  log_debug "Attempting IP-based timezone detection..."

  if ! command -v tzupdate >/dev/null 2>&1; then
    log_debug "tzupdate not available"
    return 1
  fi

  if ! ping -c1 -W3 1.1.1.1 >/dev/null 2>&1; then
    log_debug "No internet connection for IP detection"
    return 1
  fi

  # Run tzupdate in dry-run mode to get detected timezone
  local detected_tz
  detected_tz=$(tzupdate --print-only 2>/dev/null)

  if [[ -n "$detected_tz" && "$detected_tz" != "UTC" ]]; then
    log_debug "IP-based detection found: $detected_tz"
    echo "$detected_tz"
    return 0
  fi

  log_debug "IP-based detection failed or returned UTC"
  return 1
}

# Helper function: Auto-detect country from current timezone (for fallbacks)
auto_detect_country() {
  local detected_country="us" # fallback

  # Try to detect from current timezone
  if command -v timedatectl >/dev/null 2>&1; then
    local timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "")
    case "$timezone" in
      Europe/London | Europe/Edinburgh) detected_country="uk" ;;
      Europe/Berlin | Europe/Munich) detected_country="de" ;;
      Europe/Paris) detected_country="fr" ;;
      Europe/Amsterdam) detected_country="nl" ;;
      Europe/Stockholm) detected_country="se" ;;
      Europe/Copenhagen) detected_country="dk" ;;
      Europe/Oslo) detected_country="no" ;;
      Europe/Helsinki) detected_country="fi" ;;
      Europe/Rome | Europe/Milan) detected_country="it" ;;
      Europe/Madrid) detected_country="es" ;;
      Australia/*) detected_country="au" ;;
      America/Toronto | America/Montreal) detected_country="ca" ;;
      America/Sao_Paulo) detected_country="br" ;;
      Asia/Tokyo) detected_country="jp" ;;
      Asia/Seoul) detected_country="kr" ;;
      Asia/Singapore) detected_country="sg" ;;
      Asia/Kolkata | Asia/Mumbai) detected_country="in" ;;
      Asia/Shanghai | Asia/Beijing) detected_country="cn" ;;
      America/*) detected_country="us" ;;
    esac
  fi

  echo "$detected_country"
}

# Method 2: Hardware clock / RTC timezone estimation
detect_timezone_hardware() {
  log_debug "Attempting hardware-based timezone detection..."

  # Check if hardware clock is set to local time (common in dual-boot systems)
  if timedatectl show | grep -q "RTCInLocalTZ=yes"; then
    # Try to estimate timezone from hardware clock offset
    local hw_time=$(sudo hwclock --show 2>/dev/null | head -1)
    local sys_time=$(date)

    log_debug "Hardware time: $hw_time"
    log_debug "System time: $sys_time"

    # This is basic - could be enhanced with more sophisticated detection
    # For now, just indicate that hardware detection was attempted
    log_debug "Hardware clock in local time detected, but cannot reliably determine timezone"
  fi

  return 1
}

# Method 3: Interactive user selection
select_timezone_interactive() {
  log_info "Starting interactive timezone selection..."

  # Check if we have a terminal interface available
  if [[ ! -t 0 ]] || [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    log_debug "No interactive interface available"
    return 1
  fi

  # Use gum for better user interface if available
  if command -v gum >/dev/null 2>&1; then
    select_timezone_with_gum
  else
    select_timezone_basic
  fi
}

select_timezone_with_gum() {
  log_debug "Using gum for timezone selection"

  # First, ask if user wants to auto-detect or manually select
  local choice
  choice=$(gum choose --header "Timezone Configuration" \
    "Auto-detect from internet (recommended)" \
    "Select manually from list" \
    "Skip (keep current: $(timedatectl show --property=Timezone --value))")

  case "$choice" in
    "Auto-detect"*)
      local detected_tz
      detected_tz=$(detect_timezone_ip)
      if [[ $? -eq 0 && -n "$detected_tz" ]]; then
        log_info "Auto-detected timezone: $detected_tz"
        if gum confirm "Set timezone to $detected_tz?"; then
          set_timezone "$detected_tz"
          return 0
        fi
      else
        gum style --foreground 196 "Auto-detection failed. Please select manually."
        select_timezone_manual_gum
      fi
      ;;
    "Select manually"*)
      select_timezone_manual_gum
      ;;
    "Skip"*)
      log_info "User chose to skip timezone configuration"
      return 0
      ;;
  esac
}

select_timezone_manual_gum() {
  # Get list of common timezones organized by region
  local regions=("America" "Europe" "Asia" "Africa" "Australia" "Pacific")

  local selected_region
  selected_region=$(gum choose --header "Select your region:" "${regions[@]}")

  if [[ -n "$selected_region" ]]; then
    # Get timezones for the selected region
    local timezones
    readarray -t timezones < <(timedatectl list-timezones | grep "^$selected_region/" | sed "s|^$selected_region/||")

    if [[ ${#timezones[@]} -gt 0 ]]; then
      local selected_city
      selected_city=$(gum choose --header "Select your city/location:" "${timezones[@]}")

      if [[ -n "$selected_city" ]]; then
        local full_timezone="$selected_region/$selected_city"
        log_info "User selected timezone: $full_timezone"
        set_timezone "$full_timezone"
      fi
    fi
  fi
}

select_timezone_basic() {
  log_debug "Using basic timezone selection"

  echo "Timezone Configuration"
  echo "Current timezone: $(timedatectl show --property=Timezone --value)"
  echo
  echo "Options:"
  echo "1) Auto-detect from internet (recommended)"
  echo "2) Select manually"
  echo "3) Keep current"
  echo

  local choice
  read -p "Choose option [1-3]: " choice

  case "$choice" in
    1)
      local detected_tz
      detected_tz=$(detect_timezone_ip)
      if [[ $? -eq 0 && -n "$detected_tz" ]]; then
        echo "Auto-detected timezone: $detected_tz"
        read -p "Set timezone to $detected_tz? [Y/n]: " confirm
        if [[ "$confirm" != "n" && "$confirm" != "N" ]]; then
          set_timezone "$detected_tz"
          return 0
        fi
      else
        echo "Auto-detection failed."
        return 1
      fi
      ;;
    2)
      echo "Available regions:"
      echo "- America (North/South America)"
      echo "- Europe"
      echo "- Asia"
      echo "- Africa"
      echo "- Australia"
      echo "- Pacific"
      echo
      read -p "Enter region: " region

      if [[ -n "$region" ]]; then
        echo "Available locations in $region:"
        timedatectl list-timezones | grep "^$region/" | sed "s|^$region/||" | head -20
        echo
        read -p "Enter city/location: " city

        if [[ -n "$city" ]]; then
          local full_timezone="$region/$city"
          set_timezone "$full_timezone"
        fi
      fi
      ;;
    3)
      log_info "User chose to keep current timezone"
      return 0
      ;;
    *)
      echo "Invalid option"
      return 1
      ;;
  esac
}

# Set the timezone and update system
set_timezone() {
  local timezone="$1"

  if [[ -z "$timezone" ]]; then
    log_debug "No timezone provided to set_timezone"
    return 1
  fi

  log_info "Setting timezone to: $timezone"

  # Validate timezone exists
  if ! timedatectl list-timezones | grep -q "^$timezone$"; then
    log_debug "Invalid timezone: $timezone"
    echo "Error: Invalid timezone '$timezone'"
    return 1
  fi

  # Set the timezone
  if sudo timedatectl set-timezone "$timezone"; then
    log_info "Successfully set timezone to $timezone"

    # Update system time
    sudo systemctl restart systemd-timesyncd 2>/dev/null || true

    # Trigger time sync
    sudo timedatectl set-ntp true 2>/dev/null || true

    log_info "Timezone configuration completed"
    return 0
  else
    log_debug "Failed to set timezone"
    echo "Error: Failed to set timezone"
    return 1
  fi
}

# Main timezone detection workflow
main() {
  log_info "Starting timezone detection and configuration"

  # Get current timezone
  local current_tz
  current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "Unknown")
  log_info "Current timezone: $current_tz"

  # Skip if timezone is already set to something other than UTC
  if [[ "$current_tz" != "UTC" && "$current_tz" != "Unknown" && -n "$current_tz" ]]; then
    log_info "Timezone already configured: $current_tz"

    # Still try to sync time
    sudo systemctl restart systemd-timesyncd 2>/dev/null || true
    return 0
  fi

  # Try automatic detection first
  local detected_tz
  detected_tz=$(detect_timezone_ip)

  if [[ $? -eq 0 && -n "$detected_tz" ]]; then
    log_info "Successfully auto-detected timezone: $detected_tz"
    set_timezone "$detected_tz"
    return 0
  fi

  # Fall back to interactive selection if we have an interface
  if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] || [[ -t 0 ]]; then
    select_timezone_interactive
    return $?
  fi

  # If all else fails, log and continue with UTC
  log_info "Could not detect or configure timezone, keeping UTC"
  return 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
