echo "Fixing deprecated scrolltouchpad in hyprland input config for Asahi 0.54 compatibility"

TARGET_FILE="$HOME/.config/hypr/input.conf"
if [ -f "$TARGET_FILE" ] && grep -q "scrolltouchpad" "$TARGET_FILE"; then
  sed -i 's/^windowrule = scrolltouchpad/# windowrule = scrolltouchpad/' "$TARGET_FILE"
  echo "✓ Deprecated scrolltouchpad settings commented out."
fi
