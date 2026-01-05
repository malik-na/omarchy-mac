#!/bin/bash

# =============================================================================
# Omarchy Mac Bootstrap Script
# =============================================================================
# This script automates Steps 2-4 from the README:
#   - Initial Arch Linux setup (locale, packages)
#   - User account creation with sudo access
#   - AUR helper (yay) installation
#   - Omarchy Mac installation
#
# Usage (as root after first boot):
#   curl -fsSL https://raw.githubusercontent.com/malik-na/omarchy-mac/main/bootstrap.sh | bash
#   OR
#   wget -qO- https://raw.githubusercontent.com/malik-na/omarchy-mac/main/bootstrap.sh | bash
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ASCII Art Banner
print_banner() {
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
 ▀█████▀    ▀█   ███   █▀   ███   █▀   ███   ███  ███████▀   ███   █▀    ▀█████▀ 
                                       ███   █▀                                  

                        MAC BOOTSTRAP INSTALLER
EOF
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}${BOLD}==>${NC}${BOLD} $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root for initial setup."
        print_info "Please log in as root and run this script again."
        exit 1
    fi
}

# Check if running on Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        print_error "This script is designed for Arch Linux."
        exit 1
    fi
}

# Configure network if not connected
setup_network() {
    print_step "Checking network connectivity..."
    
    if ping -c 1 archlinux.org &>/dev/null; then
        print_success "Network is connected"
        return 0
    fi
    
    print_warning "No network connection detected"
    print_info "Launching nmtui for network configuration..."
    echo -e "${YELLOW}Please configure your WiFi connection, then exit nmtui to continue.${NC}"
    sleep 2
    nmtui
    
    # Verify connection after nmtui
    sleep 3
    if ping -c 1 archlinux.org &>/dev/null; then
        print_success "Network connected successfully"
    else
        print_error "Network still not connected. Please configure manually and rerun this script."
        exit 1
    fi
}

# Configure locale
setup_locale() {
    print_step "Configuring locale..."
    
    # Check if en_US.UTF-8 is already configured
    if locale 2>/dev/null | grep -q "en_US.UTF-8"; then
        print_success "Locale already configured"
        return 0
    fi
    
    # Enable en_US.UTF-8 in locale.gen
    if grep -q "^#en_US.UTF-8" /etc/locale.gen; then
        sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
        print_success "Enabled en_US.UTF-8 in locale.gen"
    fi
    
    # Generate locale
    locale-gen
    print_success "Generated locales"
    
    # Set locale.conf
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    print_success "Set LANG=en_US.UTF-8 in locale.conf"
    
    # Export for current session
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
}

# Update system and install essential packages
install_packages() {
    print_step "Updating system and installing essential packages..."
    
    # Update package database and system
    pacman -Syu --noconfirm
    print_success "System updated"
    
    # Install essential packages
    pacman -S --noconfirm --needed sudo git base-devel chromium gum
    print_success "Essential packages installed (sudo, git, base-devel, chromium, gum)"
}

# Create user account
create_user() {
    print_step "User Account Setup"
    
    # Check if we should skip user creation (if non-root user already exists in wheel group)
    existing_user=$(getent group wheel | cut -d: -f4 | tr ',' '\n' | grep -v '^$' | head -n1)
    
    if [[ -n "$existing_user" && "$existing_user" != "root" ]]; then
        print_info "Existing user found: $existing_user"
        echo -en "${YELLOW}Use existing user '$existing_user'? [Y/n]:${NC} "
        read -r use_existing
        if [[ ! "$use_existing" =~ ^[Nn]$ ]]; then
            NEW_USER="$existing_user"
            print_success "Using existing user: $NEW_USER"
            return 0
        fi
    fi
    
    # Prompt for username
    while true; do
        echo -en "${CYAN}Enter username for new account:${NC} "
        read -r NEW_USER
        
        # Validate username
        if [[ -z "$NEW_USER" ]]; then
            print_error "Username cannot be empty"
            continue
        fi
        
        if [[ ! "$NEW_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            print_error "Invalid username. Use lowercase letters, numbers, underscores, and hyphens."
            continue
        fi
        
        if id "$NEW_USER" &>/dev/null; then
            print_warning "User '$NEW_USER' already exists"
            echo -en "${YELLOW}Use this existing user? [Y/n]:${NC} "
            read -r use_existing
            if [[ ! "$use_existing" =~ ^[Nn]$ ]]; then
                # Ensure user is in wheel group
                usermod -aG wheel "$NEW_USER"
                print_success "Added $NEW_USER to wheel group"
                break
            fi
            continue
        fi
        
        break
    done
    
    # Create user if doesn't exist
    if ! id "$NEW_USER" &>/dev/null; then
        useradd -m -G wheel "$NEW_USER"
        print_success "Created user: $NEW_USER"
        
        # Set password
        print_info "Set password for $NEW_USER:"
        while ! passwd "$NEW_USER"; do
            print_error "Passwords did not match. Please try again."
        done
        print_success "Password set for $NEW_USER"
    fi
}

# Configure sudo
setup_sudo() {
    print_step "Configuring sudo access..."
    
    # Check if wheel group already has sudo access
    if grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers 2>/dev/null; then
        print_success "Sudo already configured for wheel group"
        return 0
    fi
    
    # Ask about NOPASSWD preference
    echo -e "${CYAN}Sudo configuration options:${NC}"
    echo "  1) Standard (password required for sudo commands)"
    echo "  2) NOPASSWD (no password prompts - smoother installation)"
    echo -en "${YELLOW}Choose option [1/2, default=2]:${NC} "
    read -r sudo_option
    
    # Backup sudoers
    cp /etc/sudoers /etc/sudoers.backup
    
    if [[ "$sudo_option" == "1" ]]; then
        # Enable wheel group with password
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        print_success "Enabled sudo with password for wheel group"
    else
        # Enable wheel group without password (smoother install experience)
        sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
        print_success "Enabled sudo without password for wheel group (NOPASSWD)"
        print_info "You can change this later by running: sudo EDITOR=nano visudo"
    fi
    
    # Verify sudoers file is valid
    if ! visudo -c &>/dev/null; then
        print_error "Sudoers file validation failed. Restoring backup..."
        cp /etc/sudoers.backup /etc/sudoers
        exit 1
    fi
}

# Install yay AUR helper
install_yay() {
    print_step "Installing yay AUR helper..."
    
    # Check if yay is already installed
    if command -v yay &>/dev/null; then
        print_success "yay is already installed"
        return 0
    fi
    
    # Install yay as the new user
    sudo -u "$NEW_USER" bash << 'EOFYAY'
        set -e
        cd /tmp
        rm -rf yay
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
EOFYAY
    
    print_success "yay AUR helper installed"
}

# Clone and install Omarchy Mac
install_omarchy() {
    print_step "Installing Omarchy Mac..."
    
    OMARCHY_PATH="/home/$NEW_USER/.local/share/omarchy"
    
    # Use custom repo if specified
    OMARCHY_REPO="${OMARCHY_REPO:-malik-na/omarchy-mac}"
    OMARCHY_REF="${OMARCHY_REF:-main}"
    
    print_info "Cloning from: https://github.com/${OMARCHY_REPO}.git"
    
    # Clone repository as the new user
    sudo -u "$NEW_USER" bash -c "
        rm -rf '$OMARCHY_PATH'
        mkdir -p '$(dirname "$OMARCHY_PATH")'
        git clone 'https://github.com/${OMARCHY_REPO}.git' '$OMARCHY_PATH'
    "
    
    # Checkout specific branch if not main
    if [[ "$OMARCHY_REF" != "main" ]]; then
        print_info "Using branch: $OMARCHY_REF"
        sudo -u "$NEW_USER" bash -c "
            cd '$OMARCHY_PATH'
            git fetch origin '$OMARCHY_REF'
            git checkout '$OMARCHY_REF'
        "
    fi
    
    print_success "Omarchy Mac repository cloned"
    
    # Set online install mode
    export OMARCHY_ONLINE_INSTALL=true
    
    print_info "Starting Omarchy Mac installation..."
    print_info "This may take a while. Please wait..."
    echo ""
    
    # Run install.sh as the new user
    sudo -u "$NEW_USER" bash -c "
        export OMARCHY_ONLINE_INSTALL=true
        cd '$OMARCHY_PATH'
        bash install.sh
    "
}

# Main execution
main() {
    clear
    print_banner
    
    echo -e "${BOLD}Welcome to the Omarchy Mac Bootstrap Installer!${NC}"
    echo -e "This script will automate the initial setup process.\n"
    
    # Pre-flight checks
    check_root
    check_arch
    
    print_info "This script will:"
    echo "  • Configure network (if needed)"
    echo "  • Set up locale (en_US.UTF-8)"
    echo "  • Update system and install essential packages"
    echo "  • Create a user account with sudo access"
    echo "  • Install yay AUR helper"
    echo "  • Clone and install Omarchy Mac"
    echo ""
    
    echo -en "${YELLOW}Continue with installation? [Y/n]:${NC} "
    read -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
    
    # Run setup steps
    setup_network
    setup_locale
    install_packages
    create_user
    setup_sudo
    install_yay
    install_omarchy
    
    # Final message
    echo ""
    print_step "Installation Complete!"
    echo ""
    print_success "Omarchy Mac has been installed successfully!"
    echo ""
    print_info "Next steps:"
    echo "  1. Reboot your system: ${CYAN}reboot${NC}"
    echo "  2. Log in as: ${CYAN}$NEW_USER${NC}"
    echo "  3. Enjoy Omarchy Mac! 🎉"
    echo ""
    
    echo -en "${YELLOW}Reboot now? [Y/n]:${NC} "
    read -r do_reboot
    if [[ ! "$do_reboot" =~ ^[Nn]$ ]]; then
        print_info "Rebooting in 3 seconds..."
        sleep 3
        reboot
    fi
}

# Run main function
main "$@"
