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
  # Map architecture: aarch64 -> arm64, x86_64 -> x86_64
  ARCH=$(uname -m)
  if [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
  fi
  LAZYDOCKER_URL="https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_$(uname -s)_${ARCH}.tar.gz"
  tmpdir=$(mktemp -d)
  if curl -fL "$LAZYDOCKER_URL" -o "$tmpdir/lazydocker.tar.gz" && tar -xzf "$tmpdir/lazydocker.tar.gz" -C "$tmpdir"; then
    sudo mv "$tmpdir/lazydocker" /usr/local/bin/
    sudo chmod +x /usr/local/bin/lazydocker
  else
    echo "[WARN] Failed to install lazydocker, skipping..."
  fi
  rm -rf "$tmpdir"
fi

# 2. uwsm (pip)
if ! command -v uwsm &>/dev/null; then
  echo "Installing uwsm (pip)..."
  pip3 install --user uwsm
fi

# 2b. terminaltexteffects (tte) - for install animations
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
  sudo dnf install -y swayosd || echo "[WARN] swayosd not found in COPR, please build from source."
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
