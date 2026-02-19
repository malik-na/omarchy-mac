#!/bin/bash
stop_install_log

# Check if tte (terminaltexteffects) is available
if command -v tte &>/dev/null; then
  echo_in_style() {
    echo "$1" | tte --canvas-width 0 --anchor-text c --frame-rate 640 print
  }

  show_logo() {
    if [[ -f ~/.local/share/omarchy/logo.txt ]]; then
      tte -i ~/.local/share/omarchy/logo.txt --canvas-width 0 --anchor-text c --frame-rate 920 laseretch
    elif [[ -f "$OMARCHY_PATH/logo.txt" ]]; then
      tte -i "$OMARCHY_PATH/logo.txt" --canvas-width 0 --anchor-text c --frame-rate 920 laseretch
    else
      echo "  OMARCHY"
    fi
  }
else
  echo_in_style() {
    echo "$1"
  }

  show_logo() {
    if [[ -f ~/.local/share/omarchy/logo.txt ]]; then
      cat ~/.local/share/omarchy/logo.txt
    elif [[ -f "$OMARCHY_PATH/logo.txt" ]]; then
      cat "$OMARCHY_PATH/logo.txt"
    else
      echo "  OMARCHY"
    fi
  }
fi

clear
echo
show_logo
echo

# Display installation time if available
if [[ -f $OMARCHY_INSTALL_LOG_FILE ]] && grep -q "Total:" "$OMARCHY_INSTALL_LOG_FILE" 2>/dev/null; then
  echo
  TOTAL_TIME=$(tail -n 20 "$OMARCHY_INSTALL_LOG_FILE" | grep "^Total:" | sed 's/^Total:[[:space:]]*//')
  if [ -n "$TOTAL_TIME" ]; then
    echo_in_style "Installed in $TOTAL_TIME"
  fi
else
  echo_in_style "Finished installing"
fi

if ! command -v swayosd-server &>/dev/null; then
  echo
  echo "Note: swayosd is unavailable, so on-screen volume/brightness OSD is disabled."
  echo "Install later with: sudo dnf copr enable -y erikreider/swayosd && sudo dnf install -y swayosd"
fi

# Clean up temporary installer sudoers rule
if sudo test -f /etc/sudoers.d/99-omarchy-installer; then
  sudo rm -f /etc/sudoers.d/99-omarchy-installer &>/dev/null
fi

# Exit gracefully if user chooses not to reboot
if gum confirm --show-help=false --default --affirmative "Reboot Now" --negative "" ""; then
  # Clear screen to hide any shutdown messages
  clear

  if [[ -n "${OMARCHY_CHROOT_INSTALL:-}" ]]; then
    touch /var/tmp/omarchy-install-completed
    exit 0
  else
    sudo reboot 2>/dev/null
  fi
fi
