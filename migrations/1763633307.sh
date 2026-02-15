echo "Add 100-line split resizing keybindings to Ghostty"

if ! grep -q "resize_split:down,100" ~/.config/ghostty/config; then
  sed -i "/keybind = control+insert=copy_to_clipboard/a\keybind = super+control+shift+alt+down=resize_split:down,100\nkeybind = super+control+shift+alt+up=resize_split:up,100\nkeybind = super+control+shift+alt+left=resize_split:left,100\nkeybind = super+control+shift+alt+right=resize_split:right,100" ~/.config/ghostty/config
fi
