echo "Migrate AUR packages to official repos where possible"

reinstall_package_opr() {
  local old_package="$1"
  local new_package="${2:-$1}"

  if omarchy-pkg-present "$old_package" && pacman -Si "$new_package" &>/dev/null; then
    sudo pacman -S --noconfirm "$new_package"
    sudo pacman -Rns --noconfirm "$old_package"
  fi
}

omarchy-pkg-drop yay-bin-debug

reinstall_package_opr yay-bin yay
reinstall_package_opr obsidian-bin obsidian
reinstall_package_opr localsend-bin localsend
reinstall_package_opr omarchy-chromium-bin omarchy-chromium
reinstall_package_opr wl-screenrec
reinstall_package_opr python-terminaltexteffects
reinstall_package_opr tzupdate
reinstall_package_opr typora
reinstall_package_opr ttf-ia-writer
