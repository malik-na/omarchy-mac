# Configure keyboard backlight brightness
# Sets keyboard backlight to 50% if available

if brightnessctl --list | grep -q "kbd_backlight"; then
  echo "Setting keyboard backlight to 50%"
  brightnessctl --device=kbd_backlight set 50%
else
  sudo pacman -S brightnessctl --noconfirm
  brightnessctl --device=kbd_backlight set 50%
  echo "Keyboard backlight set to 50%"
fi