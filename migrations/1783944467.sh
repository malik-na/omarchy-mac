echo "Use media keys by default on Apple keyboards (Fn for F-keys)"

# fnmode=1 (fkeyslast): volume/brightness/media without Fn; hold Fn for F1–F12.
# Replaces the old install default of fnmode=2 (fkeysfirst).
echo "options hid_apple fnmode=1" | sudo tee /etc/modprobe.d/hid_apple.conf >/dev/null

if [[ -f /sys/module/hid_apple/parameters/fnmode ]]; then
  echo 1 | sudo tee /sys/module/hid_apple/parameters/fnmode >/dev/null || true
fi
