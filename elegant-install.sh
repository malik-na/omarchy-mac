#!/bin/bash

# =============================================================================
# Omarchy Mac Elegant Installer
# =============================================================================
# This script provides a beautiful, gum-enhanced installation experience:
#   - Installs gum if needed
#   - Clones Omarchy Mac repository 
#   - Shows elegant progress indicators and formatted output
#   - Offers to run bootstrap installer automatically
#
# Usage (as root after first boot):
#   wget -qO- https://malik-na.github.io/omarchy-mac/install.sh | bash
#   OR
#   curl -fsSL https://malik-na.github.io/omarchy-mac/install.sh | bash
# =============================================================================

set -e

# Colors for fallback if gum isn't available
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Install gum if not present
install_gum() {
    if ! command -v gum &>/dev/null; then
        if command -v gum &>/dev/null; then
            return 0
        fi
        
        echo -e "${YELLOW}Installing gum for elegant interface...${NC}"
        
        # Try to install gum
        if command -v pacman &>/dev/null; then
            pacman -Sy --noconfirm --needed gum 2>/dev/null || {
                echo -e "${YELLOW}Warning: Could not install gum automatically${NC}"
                return 1
            }
        else
            echo -e "${YELLOW}Warning: pacman not found, cannot install gum${NC}"
            return 1
        fi
    fi
}

# Show message with gum or fallback
show_message() {
    if command -v gum &>/dev/null; then
        gum format "$@"
    else
        echo -e "${CYAN}$1${NC}"
    fi
}

# Show spinner with gum or fallback
show_spinner() {
    local title="$1"
    shift
    
    if command -v gum &>/dev/null; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        echo -e "${BLUE}$title...${NC}"
        "$@"
    fi
}

# Ask for confirmation with gum or fallback
ask_confirm() {
    if command -v gum &>/dev/null; then
        gum confirm "$1"
    else
        echo -e "${YELLOW}$1 [Y/n]:${NC}"
        read -r response
        [[ ! "$response" =~ ^[Nn]$ ]]
    fi

# ASCII Art Banner
print_banner() {
    if command -v gum &>/dev/null; then
        gum style \
            --foreground 212 \
            --border double \
            --align center \
            --margin "1 2" \
            --padding "1 2" \
            "$(cat << 'EOF'
                 ▄▄▄                                                   
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄ 
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀ 
                                       ███   █▀                                  
EOF
)" \
            "$(gum style --foreground 212 --bold 'ELEGANT INSTALLER')"
    else
        echo -e "${CYAN}"
        cat << 'EOF'
                 ▄▄▄                                                   
 ▄█████▄    ▄███████████▄    ▄███████   ▄███████   ▄███████   ▄█   █▄    ▄█   █▄ 
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   █▀   ███   ███  ███   ███
███   ███  ███   ███   ███ ▄███▄▄▄███ ▄███▄▄▄██▀  ███       ▄███▄▄▄███▄ ███▄▄▄███
███   ███  ███   ███   ███ ▀███▀▀▀███ ▀███▀▀▀▀    ███      ▀▀███▀▀▀███  ▀▀▀▀▀▀███
███   ███  ███   ███   ███  ███   ███ ██████████  ███   █▄   ███   ███  ▄██   ███
███   ███  ███   ███   ███  ███   ███  ███   ███  ███   ███  ███   ███  ███   ███
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   ▀    ▀█████▀ 
                                       ███   █▀                                  
EOF
        echo -e "${NC}"
    fi
}

# Main installation flow
main() {
    clear
    print_banner
    
    # Install gum for elegant interface
    install_gum
    
    # Clone Omarchy Mac
    show_spinner "Cloning Omarchy Mac repository" \
        git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
    
    # Success message
    show_message "## ✅ Omarchy Mac cloned successfully!" \
        "" \
        "The repository has been cloned to \`~/.local/share/omarchy\`" \
        "" \
        "The bootstrap installer will:" \
        "• Configure network and locale" \
        "• Update system and install essential packages" \
        "• Create user account with sudo access" \
        "• Install AUR helper and Omarchy Mac" \
        "" \
        "To run the interactive bootstrap installer:" \
        "\`\`\`bash" \
        "cd ~/.local/share/omarchy" \
        "sudo bash bootstrap.sh" \
        "\`\`\`"
    
    # Ask if user wants to run bootstrap now
    if ask_confirm "Run bootstrap installer now?"; then
        show_message "Starting bootstrap installer..."
        cd ~/.local/share/omarchy
        
        if [[ $EUID -ne 0 ]]; then
            show_message "⚠️  **Note**: Bootstrap requires root access" \
                "You'll be prompted for your password when needed."
        fi
        
        sudo bash bootstrap.sh
    else
        show_message "## 🎉 Ready to install!" \
            "" \
            "Run the bootstrap installer when you're ready:" \
            "\`\`\`bash" \
            "cd ~/.local/share/omarchy" \
            "sudo bash bootstrap.sh" \
            "\`\`\`"
    fi
}

# Run main function
main "$@"