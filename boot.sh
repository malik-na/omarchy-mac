#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export OMARCHY_ONLINE_INSTALL=true

# When running via `wget ... | bash`, stdin is the pipe and may be EOF.
# Reattach stdin to the controlling terminal so any interactive prompts work.
if [[ ! -t 0 ]] && [[ -r /dev/tty ]]; then
    exec </dev/tty
fi

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

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
        ${SUDO:+$SUDO }pacman -S --noconfirm --needed gum 2>/dev/null || {
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

# Validate privileges / sudo if needed
if [[ -n "$SUDO" ]]; then
    if ! command -v sudo &>/dev/null; then
        show_message '❌ **Error**: `sudo` is required when not running as root.'
        show_message "Run this script as root, or install sudo and re-run."
        exit 1
    fi

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
fi

show_spinner "Updating package database and installing git" \
    ${SUDO:+$SUDO }pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to malik-na/omarchy-mac
OMARCHY_REPO="${OMARCHY_REPO:-malik-na/omarchy-mac}"

show_spinner "Cloning Omarchy Mac repository" \
    bash -lc 'set -e; target="$HOME/.local/share/omarchy"; mkdir -p "$(dirname "$target")"; rm -rf "$target"; git clone "https://github.com/'"$OMARCHY_REPO"'.git" "$target"'

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

# Start bootstrap installer automatically
show_message "**Starting bootstrap installer...**"
clear
cd ~/.local/share/omarchy
${SUDO:+$SUDO }bash bootstrap.sh
