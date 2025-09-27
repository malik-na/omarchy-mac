echo "Migrate AUR packages to official repos where possible"

reinstall_package_opr() {
  if ! omarchy-pkg-present "$1"; then
    echo "Source package '$1' not installed, skipping."
    return 1
  fi

  if ! pacman -Si "${2:-$1}" &>/dev/null; then
    echo "Target package '${2:-$1}' not found in repos, skipping."
    return 1
  fi

  sudo pacman -Rns --noconfirm "$1"
  sudo pacman -S --noconfirm "${2:-$1}"
}

omarchy-pkg-drop yay-bin-debug

reinstall_package_opr yay-bin yay
reinstall_package_opr obsidian-bin obsidian
reinstall_package_opr localsend-bin localsend
reinstall_package_opr omarchy-chromium-bin omarchy-chromium
reinstall_package_opr walker-bin walker
reinstall_package_opr wl-screenrec
reinstall_package_opr python-terminaltexteffects
reinstall_package_opr tzupdate
reinstall_package_opr typora
reinstall_package_opr ttf-ia-writer
