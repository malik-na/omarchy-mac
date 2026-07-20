echo "Apple Silicon: install the browser screen-share picker + enable PipeWire capture"

# The x86 hyprland-preview-share-picker (in omarchy-base.packages) has no ARM build,
# so xdg-desktop-portal-hyprland can't show a source chooser and browser screen/window
# sharing silently falls back to tab-only. Build the source package (its AUR PKGBUILD
# includes aarch64) so the themed picker + full-screen share work.
if [[ "$(uname -m)" == "aarch64" ]] && ! command -v hyprland-preview-share-picker >/dev/null 2>&1; then
  omarchy-pkg-aur-add hyprland-preview-share-picker-git || true
fi

# Ensure Chromium/Brave route screen capture through the Wayland portal (the picker
# above is only reached when the browser uses the PipeWire capturer path).
for conf in ~/.config/{chromium,brave,chrome,microsoft-edge-stable}-flags.conf; do
  [[ -f $conf ]] || continue
  grep -q 'WebRTCPipeWireCapturer' "$conf" && continue
  if grep -q -- '--enable-features=' "$conf"; then
    sed -i 's/\(^--enable-features=[^[:space:]]*\)/\1,WebRTCPipeWireCapturer/' "$conf"
  else
    [[ -n $(tail -c1 "$conf") ]] && echo >>"$conf"
    echo '--enable-features=WebRTCPipeWireCapturer' >>"$conf"
  fi
done
