echo "Use media keys by default on Apple keyboards (Fn for F-keys)"

# fnmode=1 (fkeyslast) puts volume/brightness/media on the top row and moves
# F1-F12 behind Fn, the way macOS does. default/hypr/bindings/media.lua binds
# bare XF86MonBrightness*, so the top row has to emit media keycodes for display
# and keyboard brightness to work at all.
#
# Only replace the old install default of fnmode=2 (fkeysfirst). If the file is
# missing, write it; if it names any other mode, the user chose that, so leave it.
config=/etc/modprobe.d/hid_apple.conf

if [[ -f $config ]] && ! grep -q 'fnmode=2' "$config"; then
  echo "Keeping existing hid_apple options in $config"
  exit 0
fi

sudo mkdir -p /etc/modprobe.d
echo "options hid_apple fnmode=1" | sudo tee "$config" >/dev/null

# Apply now so the top row changes behavior without a reboot.
if [[ -f /sys/module/hid_apple/parameters/fnmode ]]; then
  echo 1 | sudo tee /sys/module/hid_apple/parameters/fnmode >/dev/null || true
fi
