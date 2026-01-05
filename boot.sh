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
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   ▀    ▀█████▀ 
                                       ███   █▀                                  '

# Install gum if not present for enhanced UI
install_gum() {
    if ! command -v gum &>/dev/null; then
        echo "Installing gum for elegant interface..."
        sudo pacman -S --noconfirm --needed gum 2>/dev/null || {
            echo "Warning: Could not install gum, falling back to basic interface"
            return 1
        }
    fi
}

# Show message with gum or fallback
show_message() {
    if command -v gum &>/dev/null; then
        gum format "$@"
    else
        echo -e "$1"
    fi
}

# Show spinner with gum or fallback
show_spinner() {
    local title="$1"
    shift
    
    if command -v gum &>/dev/null; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        echo "$title..."
        "$@"
    fi
}

# Ask for confirmation with gum or fallback
ask_confirm() {
    if command -v gum &>/dev/null; then
        gum confirm "$1"
    else
        echo "$1 [Y/n]:"
        read -r response
        [[ ! "$response" =~ ^[Nn]$ ]]
    fi
}

clear

# Show banner with gum or fallback
if command -v gum &>/dev/null; then
    gum style \
        --foreground 212 \
        --border double \
        --align center \
        --margin "1 2" \
        --padding "1 2" \
        "$ansi_art" \
        "$(gum style --foreground 212 --bold 'OMARCHY MAC BOOTSTRAP')"
else
    echo -e "\n$ansi_art\n"
fi

# Install gum for better experience
install_gum

# Validate sudo access and refresh timestamp to minimize password prompts
show_message "🔐 **Validating administrator access...**"
if ! sudo -v; then
  show_message "❌ **Error**: sudo access required. Please run with proper permissions."
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

show_spinner "Updating package database and installing git" \
    sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to malik-na/omarchy-mac
OMARCHY_REPO="${OMARCHY_REPO:-malik-na/omarchy-mac}"

show_spinner "Cloning Omarchy Mac repository" \
    git clone "https://github.com/${OMARCHY_REPO}.git" ~/.local/share/omarchy

# Use custom branch if instructed, otherwise default to main
OMARCHY_REF="${OMARCHY_REF:-main}"
if [[ $OMARCHY_REF != "main" ]]; then
    echo "Using branch: $OMARCHY_REF"
    cd ~/.local/share/omarchy
    git fetch origin "${OMARCHY_REF}" && git checkout "${OMARCHY_REF}"
    cd -
fi

# Success message
show_message "## ✅ Omarchy Mac cloned successfully!" \
    "" \
    "The repository has been cloned to \`~/.local/share/omarchy\`" \
    "" \
    "For new installations, run the bootstrap installer:" \
    "\`\`\`bash" \
    "cd ~/.local/share/omarchy" \
    "sudo bash bootstrap.sh" \
    "\`\`\`" \
    "" \
    "The bootstrap script will:" \
    "• Configure network and locale" \
    "• Update system and install essential packages" \
    "• Create user account with sudo access" \
    "• Install AUR helper and Omarchy Mac"

# Ask if user wants to run bootstrap now
if ask_confirm "Run bootstrap installer now?"; then
    show_message "**Starting bootstrap installer...**"
    cd ~/.local/share/omarchy
    sudo bash bootstrap.sh
else
    show_message "## 🎉 Ready to install!" \
        "" \
        "Run bootstrap installer when you're ready:" \
        "\`\`\`bash" \
        "cd ~/.local/share/omarchy" \
        "sudo bash bootstrap.sh" \
        "\`\`\`"
fi
