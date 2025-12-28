#!/bin/bash
# Ensure Walker service is started automatically on boot
mkdir -p ~/.config/autostart/
cp $OMARCHY_PATH/autostart/walker.desktop ~/.config/autostart/

# Create pacman hook to restart walker after updates (Arch only)
OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"
if is_arch; then
	sudo mkdir -p /etc/pacman.d/hooks
	sudo tee /etc/pacman.d/hooks/walker-restart.hook > /dev/null << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = walker
Target = walker-debug
Target = elephant*

[Action]
Description = Restarting Walker services after system update
When = PostTransaction
Exec = $OMARCHY_PATH/bin/omarchy-restart-walker
EOF
fi

# Link the visual theme menu config
mkdir -p ~/.config/elephant/menus
ln -snf $OMARCHY_PATH/default/elephant/omarchy_themes.lua ~/.config/elephant/menus/omarchy_themes.lua
