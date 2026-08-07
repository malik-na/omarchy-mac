# Prefer media keys on Apple-like keyboards, with Fn for F1-F12, the way macOS
# does. The Mac media bindings depend on it: default/hypr/bindings/media.lua
# binds bare XF86MonBrightness* and SHIFT+XF86MonBrightness*, so the top row has
# to emit media keycodes without Fn for display and keyboard brightness to work.
if [[ ! -f /etc/modprobe.d/hid_apple.conf ]]; then
  sudo mkdir -p /etc/modprobe.d
  echo "options hid_apple fnmode=1" | sudo tee /etc/modprobe.d/hid_apple.conf >/dev/null
fi
