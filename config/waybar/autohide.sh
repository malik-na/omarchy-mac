#!/bin/bash

# Kill any instance of waybar then relaunch it and kill it again.
# I assure you no waybars are harmed during this process.
sleep 5

killall waybar
sleep 0.8
waybar &
sleep 0.8
pkill -SIGUSR1 waybar
sleep 0.5

hyprctl notify 0 6500 "rgb(255,105,180)" "Top bar hidden. Push your mouse up to show it."
# Continuously checking the cursor position and toggling the bar accordingly
while true; do
  Y_POS=$(hyprctl cursorpos | awk -F',' '{print $2}' | tr -d ' ')

  # Check if mouse is at the top edge
  if [ "$Y_POS" -eq 0 ]; then

    pkill -SIGUSR1 waybar

    # This inner loop runs *only* while the mouse is on the bar.
    # It traps the script, keeping the bar open.
    while [ "$Y_POS" -le 30 ]; do
      sleep 0.2
      Y_POS=$(hyprctl cursorpos | awk -F',' '{print $2}' | tr -d ' ')
    done

    # Hide the bar when cursor leaves the bar (set to size 30).
    pkill -SIGUSR1 waybar

  fi

  sleep 0.2
done
