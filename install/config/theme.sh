#!/bin/bash
# Set links for Nautilius action icons
if [[ -d /usr/share/icons/Yaru/scalable/actions ]]; then
  sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-previous-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-previous-symbolic.svg
  sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-next-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-next-symbolic.svg
else
  echo "[SKIP] Yaru icon directory not present"
fi

# Setup user theme folder
mkdir -p ~/.config/omarchy/themes

# Set initial theme
omarchy-theme-set "Tokyo Night"
rm -rf ~/.config/chromium/SingletonLock # otherwise archiso will own the chromium singleton

# Set specific app links for current theme
mkdir -p ~/.config/btop/themes
ln -snf ~/.config/omarchy/current/theme/btop.theme ~/.config/btop/themes/current.theme

mkdir -p ~/.config/mako
ln -snf ~/.config/omarchy/current/theme/mako.ini ~/.config/mako/config

mkdir -p ~/.config/eza
ln -snf ~/.config/omarchy/current/theme/eza.yml ~/.config/eza/theme.yml

# Setup fuzzel theming (similar to other app configs)
mkdir -p ~/.config/fuzzel
cp -n ~/.local/share/omarchy/config/fuzzel/fuzzel.ini ~/.config/fuzzel/fuzzel.ini

# Ensure all themes have fuzzel.ini files
~/.local/share/omarchy/bin/omarchy-mac-custom-theme-utility

# Add managed policy directories for Chromium and Brave for theme changes
sudo mkdir -p /etc/chromium/policies/managed

sudo mkdir -p /etc/brave/policies/managed
