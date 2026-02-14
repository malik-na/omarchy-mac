#!/bin/bash
# Fedora manual install steps for Omarchy
# Installs packages not available in Fedora repos or COPR

OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

if ! is_fedora; then
  exit 0
fi

# 1. lazydocker (GitHub binary)
if ! command -v lazydocker &>/dev/null; then
  echo "Installing lazydocker (GitHub binary)..."
  OS_NAME=$(uname -s)
  ARCH_NAME=$(uname -m)
  case "$ARCH_NAME" in
    aarch64) ARCH_NAME="arm64" ;;
    x86_64) ARCH_NAME="x86_64" ;;
  esac

  latest_tag=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -1)

  if [[ -z "$latest_tag" ]]; then
    echo "[WARN] Could not determine lazydocker latest version, skipping..."
  else
    LAZYDOCKER_URL="https://github.com/jesseduffield/lazydocker/releases/download/${latest_tag}/lazydocker_${latest_tag#v}_${OS_NAME}_${ARCH_NAME}.tar.gz"

    tmpdir=$(mktemp -d)
    if curl -fL "$LAZYDOCKER_URL" -o "$tmpdir/lazydocker.tar.gz" && tar -xzf "$tmpdir/lazydocker.tar.gz" -C "$tmpdir"; then
      sudo mv "$tmpdir/lazydocker" /usr/local/bin/
      sudo chmod +x /usr/local/bin/lazydocker
    else
      echo "[WARN] Failed to install lazydocker, skipping..."
    fi
    rm -rf "$tmpdir"
  fi
fi

# 2. terminaltexteffects (tte) - for install animations
if ! command -v tte &>/dev/null; then
  echo "Installing terminaltexteffects (pip)..."
  pip3 install --user terminaltexteffects
fi

# 3. mise (install script)
if ! command -v mise &>/dev/null; then
  echo "Installing mise (install script)..."
  curl https://mise.jdx.dev/install.sh | bash
fi

# 4. typora (Flatpak)
if ! command -v typora &>/dev/null; then
  echo "Installing typora (Flatpak)..."
  flatpak install -y flathub io.typora.Typora
fi

# 5. localsend (Flatpak)
if ! command -v localsend &>/dev/null; then
  echo "Installing localsend (Flatpak)..."
  flatpak install -y flathub org.localsend.localsend_app
fi

# 6. swayosd (COPR or build from source)
if ! command -v swayosd-server &>/dev/null; then
  echo "Installing swayosd (COPR or build from source)..."
  sudo dnf copr enable -y atim/swayosd || true
  if dnf list --available swayosd &>/dev/null; then
    sudo dnf install -y swayosd
  else
    echo "[WARN] swayosd not found in enabled repositories, skipping automatic install."
  fi
fi

# 7. satty (build from source)
if ! command -v satty &>/dev/null; then
  echo "[WARN] satty not available in repos. Please build from source: https://github.com/marvinborner/satty"
fi

# 8. hyprland-guiutils (build from source)
if ! command -v hyprland-guiutils &>/dev/null; then
  echo "[WARN] hyprland-guiutils not available in repos. Please build from source: https://github.com/hyprwm/hyprland-guiutils"
fi

echo "Fedora manual install steps complete."
