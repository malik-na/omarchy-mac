# Prefer media/special keys by default on Apple keyboards (Fn for F1–F12).
# Matches macOS; Hyprland volume/brightness binds use XF86* media keycodes.
if [[ ! -f /etc/modprobe.d/hid_apple.conf ]]; then
  echo "options hid_apple fnmode=1" | sudo tee /etc/modprobe.d/hid_apple.conf
fi
