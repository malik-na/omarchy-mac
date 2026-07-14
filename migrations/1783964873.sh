echo "Remove leftover Walker autostart, systemd drop-in, and pacman hook"

# Walker install is a no-op on Omarchy Mac (fuzzel). Prior installs left scaffolding
# that still tries to start/restart Walker on login and after package upgrades.

rm -f "$HOME/.config/autostart/walker.desktop"

rm -f "$HOME/.config/systemd/user/app-walker@autostart.service.d/restart.conf"
rmdir "$HOME/.config/systemd/user/app-walker@autostart.service.d" 2>/dev/null || true

if omarchy-cmd-present systemctl; then
  systemctl --user disable --now 'app-walker@autostart.service' 2>/dev/null || true
  systemctl --user daemon-reload 2>/dev/null || true
fi

if [[ -f /etc/pacman.d/hooks/walker-restart.hook ]]; then
  sudo rm -f /etc/pacman.d/hooks/walker-restart.hook
fi

# Elephant menu symlinks were only used by Walker/Elephant pickers (now fuzzel)
rm -f "$HOME/.config/elephant/menus/omarchy_themes.lua"
rm -f "$HOME/.config/elephant/menus/omarchy_background_selector.lua"
rm -f "$HOME/.config/elephant/menus/omarchy_unlocks.lua"
rmdir "$HOME/.config/elephant/menus" 2>/dev/null || true
rmdir "$HOME/.config/elephant" 2>/dev/null || true
