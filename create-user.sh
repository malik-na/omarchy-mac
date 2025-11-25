#!/bin/bash

# Check if gum is installed
if ! command -v gum &>/dev/null; then
  # echo "Error: gum is not installed. Please install it with 'pacman -S gum'."
  pacman -S gum --noconfirm
  exit 1
fi

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  gum style --foreground 196 "This script must be run as root"
  exit 1
fi

# Prompt for username using gum
gum style --foreground 33 "Please enter the username for the new user:"
USERNAME=$(gum input --placeholder "Enter username")

# Check if username was provided
if [ -z "$USERNAME" ]; then
  gum style --foreground 196 "Error: No username provided"
  exit 1
fi

# Create user with home directory and add to wheel group
gum style --foreground 34 "Creating user $USERNAME with home directory and adding to wheel group..."
useradd -m -G wheel "$USERNAME"

# Set password for the new user using gum for prompt
gum style --foreground 34 "Setting password for $USERNAME"
passwd "$USERNAME"

# Configure sudoers file to enable wheel group
gum style --foreground 34 "Configuring sudoers file..."
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Verify the change in sudoers file
if grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
  gum style --foreground 34 "Wheel group successfully enabled in sudoers"
else
  gum style --foreground 196 "Failed to enable wheel group in sudoers"
  exit 1
fi

# Switch to the new user
gum style --foreground 34 "Switching to user $USERNAME"
su - "$USERNAME"
