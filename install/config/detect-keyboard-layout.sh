#!/bin/bash

conf="/etc/vconsole.conf"
hyprconf="$HOME/.config/hypr/hyprland.conf"

# Prompt user for keyboard layout
echo "Please select your keyboard layout:"
echo "1) US (Standard)"
echo "2) Macintosh (US)"
echo "3) Other (You will be prompted to enter it)"
read -p "Enter your choice (1-3): " choice

layout=""
variant=""

case $choice in
    1)
        layout="us"
        ;;
    2)
        layout="us"
        variant="mac"
        ;;
    3)
        read -p "Enter keyboard layout (e.g., us, de, fr): " layout
        read -p "Enter keyboard variant (optional, e.g., mac, altgr-intl): " variant
        ;;
    *)
        echo "Invalid choice. Defaulting to US layout."
        layout="us"
        ;;
esac

# Apply layout to vconsole.conf (for TTY)
sudo sed -i "/^XKBLAYOUT=/c\XKBLAYOUT="$layout"" "$conf"
if [[ -n "$variant" ]]; then
    sudo sed -i "/^XKBVARIANT=/c\XKBVARIANT="$variant"" "$conf"
else
    sudo sed -i "/^XKBVARIANT=/d" "$conf"
fi

# Apply layout to Hyprland config
sed -i "/^[[:space:]]*kb_layout *=/c\    kb_layout = $layout" "$hyprconf"
if [[ -n "$variant" ]]; then
    sed -i "/^[[:space:]]*kb_variant *=/c\    kb_variant = $variant" "$hyprconf"
else
    sed -i "/^[[:space:]]*kb_variant *=/d" "$hyprconf"
fi

echo "Keyboard layout set to $layout $variant."

