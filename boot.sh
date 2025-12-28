#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export OMARCHY_ONLINE_INSTALL=true

ansi_art='                 ▄▄▄                                                   
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄ 
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀ 
                                       ███   █▀                                  '

clear
echo -e "\n$ansi_art\n"

# Validate sudo access and refresh timestamp to minimize password prompts
echo "🔐 Omarchy Mac Installation requires administrator access..."
if ! sudo -v; then
  echo "❌ Error: sudo access required. Please run with proper permissions."
  exit 1
fi

# Keep sudo alive during bootstrap
keep_sudo_alive() {
  while true; do
    sudo -v
    sleep 50
  done
}

keep_sudo_alive &
SUDO_KEEPALIVE_PID=$!

# Cleanup on exit
trap 'sudo -k; kill ${SUDO_KEEPALIVE_PID:-} 2>/dev/null' EXIT INT TERM

# ============================================================================
# Safety Check: Warn if uncommitted changes exist
# ============================================================================

if [[ -d ~/.local/share/omarchy/.git ]]; then
  if [[ -n "$(git -C ~/.local/share/omarchy status --porcelain 2>/dev/null)" ]]; then
    echo -e "\n⚠️  \e[33mWarning: Uncommitted changes detected in ~/.local/share/omarchy/\e[0m"
    echo "   Running this script will DELETE all local changes!"
    echo ""
    read -t 10 -p "   Continue and DELETE? (y/N, auto-cancels in 10s): " confirm
    echo ""
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "❌ Aborted. Push your changes first, then re-run."
      exit 1
    fi
  fi
fi

# ============================================================================
# Distro Detection & Branch Selection
# ============================================================================

detect_distro() {
  if [[ -f /etc/fedora-release ]]; then
    echo "fedora"
  elif [[ -f /etc/arch-release ]]; then
    echo "arch"
  else
    echo "unknown"
  fi
}

select_distro_branch() {
  local detected_distro
  detected_distro=$(detect_distro)
  
  # If branch explicitly set via environment variable, use it
  if [[ -n "${OMARCHY_REF:-}" ]]; then
    OMARCHY_BRANCH="$OMARCHY_REF"
    return
  fi
  
  # Auto-detect based on current distro
  case "$detected_distro" in
    fedora)
      echo -e "\n🐧 Detected: \e[34mFedora Asahi Remix\e[0m"
      DETECTED_BRANCH="fedora-asahi"
      ;;
    arch)
      echo -e "\n🐧 Detected: \e[36mArch Linux (Asahi Alarm)\e[0m"
      DETECTED_BRANCH="main"
      ;;
    *)
      echo -e "\n⚠️  Could not detect distro. Please select manually:"
      DETECTED_BRANCH=""
      ;;
  esac
  
  # If detection worked, offer choice with auto-continue
  if [[ -n "$DETECTED_BRANCH" ]]; then
    echo -e "   Will install from branch: \e[33m$DETECTED_BRANCH\e[0m"
    echo ""
    echo "   Press [1] for Arch (Asahi Alarm)"
    echo "   Press [2] for Fedora Asahi Remix"
    echo "   Press [Enter] to continue with detected distro"
    echo ""
    
    # Wait for input with 10 second timeout
    read -t 10 -n 1 -p "   Select [1/2/Enter] (auto-continues in 10s): " choice
    echo ""
    
    case "$choice" in
      1) OMARCHY_BRANCH="main" ;;
      2) OMARCHY_BRANCH="fedora-asahi" ;;
      *) OMARCHY_BRANCH="$DETECTED_BRANCH" ;;
    esac
  else
    # Manual selection required
    while true; do
      echo ""
      echo "   [1] Arch Linux (Asahi Alarm)"
      echo "   [2] Fedora Asahi Remix"
      echo ""
      read -n 1 -p "   Select your distro [1/2]: " choice
      echo ""
      
      case "$choice" in
        1) OMARCHY_BRANCH="main"; break ;;
        2) OMARCHY_BRANCH="fedora-asahi"; break ;;
        *) echo "   Please select 1 or 2" ;;
      esac
    done
  fi
}

# Get the branch to use (sets OMARCHY_BRANCH global variable)
select_distro_branch

echo -e "\n📦 Installing Omarchy for: \e[32m$OMARCHY_BRANCH\e[0m"

# ============================================================================
# Package Manager Setup (distro-specific)
# ============================================================================

if [[ -f /etc/fedora-release ]]; then
  echo -e "\n🔄 Updating system packages (dnf)..."
  sudo dnf upgrade -y --refresh
  sudo dnf install -y git
else
  echo -e "\n🔄 Updating system packages (pacman)..."
  sudo pacman -Syu --noconfirm --needed git
fi

# ============================================================================
# Clone Repository
# ============================================================================

# Use custom repo if specified, otherwise default to malik-na/omarchy-mac
OMARCHY_REPO="${OMARCHY_REPO:-malik-na/omarchy-mac}"

echo -e "\nCloning Omarchy from: https://github.com/${OMARCHY_REPO}.git (branch: $OMARCHY_BRANCH)"
rm -rf ~/.local/share/omarchy/
git clone -b "$OMARCHY_BRANCH" "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy >/dev/null

echo -e "\nInstallation starting..."
source ~/.local/share/omarchy/install.sh
