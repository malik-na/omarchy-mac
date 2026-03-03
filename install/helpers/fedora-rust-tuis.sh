#!/bin/bash

OMARCHY_INSTALL="${OMARCHY_INSTALL:-$HOME/.local/share/omarchy/install}"
source "$OMARCHY_INSTALL/helpers/distro.sh"

if ! is_fedora; then
  exit 0
fi

FEDORA_RELEASE=$(rpm -E %fedora)
CPU_ARCH=$(uname -m)

echo "[Omarchy/Fedora] Ensuring TUI prerequisites (bluetui, impala, wiremix)..."

ensure_iwd_backend() {
  local backend_conf="/etc/NetworkManager/conf.d/10-wifi-backend.conf"

  if ! command -v NetworkManager >/dev/null 2>&1 && ! rpm -q NetworkManager >/dev/null 2>&1; then
    echo "[WARN] NetworkManager is not installed; skipping iwd backend setup"
    return 1
  fi

  if ! rpm -q iwd >/dev/null 2>&1; then
    echo "[INFO] Installing iwd backend package"
    sudo dnf install -y iwd || {
      echo "[WARN] Failed to install iwd"
      return 1
    }
  else
    echo "[OK] iwd already installed"
  fi

  sudo mkdir -p /etc/NetworkManager/conf.d
  if [[ ! -f "$backend_conf" ]] || ! grep -q '^\s*wifi\.backend\s*=\s*iwd\s*$' "$backend_conf"; then
    printf '[device]\nwifi.backend=iwd\n' | sudo tee "$backend_conf" >/dev/null || {
      echo "[WARN] Failed to write NetworkManager iwd backend config"
      return 1
    }
    echo "[OK] Set NetworkManager Wi-Fi backend to iwd"
  else
    echo "[OK] NetworkManager already configured with wifi.backend=iwd"
  fi

  sudo systemctl disable --now wpa_supplicant >/dev/null 2>&1 || true
  sudo systemctl enable --now iwd >/dev/null 2>&1 || {
    echo "[WARN] Failed to enable iwd service"
    return 1
  }
  sudo systemctl restart NetworkManager >/dev/null 2>&1 || {
    echo "[WARN] Failed to restart NetworkManager"
    return 1
  }

  echo "[OK] iwd backend active path configured"
}

ensure_local_bin_path() {
  mkdir -p "$HOME/.local/bin"
  case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.bashrc"
    fi
    ;;
  esac
}

install_bluetui() {
  if command -v bluetui >/dev/null 2>&1 || rpm -q bluetui >/dev/null 2>&1; then
    echo "[OK] bluetui already installed"
    return 0
  fi

  if dnf list --available bluetui >/dev/null 2>&1; then
    sudo dnf install -y bluetui && echo "[OK] bluetui installed from available repo" && return 0
  fi

  if [[ "$CPU_ARCH" == "aarch64" && "$FEDORA_RELEASE" == "42" ]]; then
    echo "[INFO] Fedora Asahi Remix 42 on aarch64 detected"
    echo "[INFO] Enabling COPR nclundell/fedora-extras using fedora-43-aarch64 chroot fallback"
    sudo dnf copr enable -y nclundell/fedora-extras fedora-43-aarch64 || sudo dnf copr enable -y nclundell/fedora-extras || true
  else
    sudo dnf copr enable -y nclundell/fedora-extras || true
  fi

  if dnf list --available bluetui >/dev/null 2>&1; then
    sudo dnf install -y bluetui && echo "[OK] bluetui installed" && return 0
  fi

  echo "[WARN] bluetui is still unavailable after COPR enable"
  return 1
}

ensure_rust_toolchain() {
  if command -v cargo >/dev/null 2>&1 && command -v rustc >/dev/null 2>&1; then
    echo "[OK] rustc/cargo already available"
    return 0
  fi

  echo "[INFO] Installing rust toolchain from Fedora repos"
  sudo dnf install -y rust cargo || return 1
}

ensure_wiremix_build_deps() {
  if rpm -q pipewire-devel >/dev/null 2>&1; then
    return 0
  fi

  echo "[INFO] Installing build dependency: pipewire-devel"
  sudo dnf install -y pipewire-devel || return 1
}

install_cargo_tool() {
  local name="$1"
  local version="$2"

  if command -v "$name" >/dev/null 2>&1 || [[ -x "$HOME/.cargo/bin/$name" ]]; then
    echo "[OK] $name already installed"
    return 0
  fi

  if ! cargo install --locked "$name" --version "$version"; then
    echo "[WARN] cargo install failed for $name"
    return 1
  fi

  ensure_local_bin_path
  ln -sf "$HOME/.cargo/bin/$name" "$HOME/.local/bin/$name"
  echo "[OK] $name installed via cargo ($version)"
}

install_bluetui
ensure_rust_toolchain || echo "[WARN] rust toolchain setup failed"
ensure_wiremix_build_deps || echo "[WARN] wiremix dependency setup failed"
install_cargo_tool impala 0.7.3 || true
install_cargo_tool wiremix 0.9.0 || true
# Switch Wi-Fi backend to iwd AFTER cargo builds — switching earlier drops the
# active Wi-Fi connection before NetworkManager/iwd handshake, which kills DNS
# and causes all subsequent network calls (cargo, dnf) to fail.
ensure_iwd_backend || echo "[WARN] iwd backend setup failed"

echo
echo "Summary of actions:"
echo "- Identified System: Fedora ${FEDORA_RELEASE} on ${CPU_ARCH}."
echo "- Tried COPR: nclundell/fedora-extras (with fedora-43-aarch64 fallback on Asahi Fedora 42)."
if systemctl is-active --quiet iwd; then
  echo "- Wi-Fi backend: iwd active (NetworkManager backend target: iwd)."
else
  echo "- Wi-Fi backend: iwd not active (check /etc/NetworkManager/conf.d/10-wifi-backend.conf)."
fi
if rpm -q bluetui >/dev/null 2>&1; then
  echo "- Installed Package: $(rpm -q bluetui)."
else
  echo "- Installed Package: bluetui not installed."
fi
