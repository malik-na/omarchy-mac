#!/usr/bin/env bash
# Install zsh configuration for new Omarchy installations

set -euo pipefail

echo "Setting up zsh..."

# Check if zsh is installed
if ! command -v zsh &> /dev/null; then
    echo "Warning: zsh is not installed. Skipping zsh setup."
    echo "You can install zsh later with: yay -S zsh"
    echo "Then run: omarchy-setup-zsh"
    exit 0
fi

# Run the setup script non-interactively for new installations
# This will auto-configure zsh with bash auto-launch
ZSHRC="${HOME}/.zshrc"
BASHRC="${HOME}/.bashrc"
ZSHRC_DEFAULT="${HOME}/.local/share/omarchy/default/zshrc"
BASHRC_DEFAULT="${HOME}/.local/share/omarchy/default/bashrc"

# Install .zshrc
if [ ! -f "${ZSHRC}" ]; then
    cp "${ZSHRC_DEFAULT}" "${ZSHRC}"
    echo "✓ Installed .zshrc"
else
    echo "✓ .zshrc already exists, skipping"
fi

# Configure bash to auto-launch zsh
if [ -f "${BASHRC}" ] && ! grep -q "Auto-launch zsh shell" "${BASHRC}" 2>/dev/null; then
    # Backup existing bashrc
    BASHRC_BACKUP="${HOME}/.bashrc.backup-$(date +%Y%m%d-%H%M%S)"
    cp "${BASHRC}" "${BASHRC_BACKUP}"
    
    # Read existing content
    EXISTING_BASHRC=$(cat "${BASHRC}")
    
    # Create new bashrc with auto-launch
    cat > "${BASHRC}" << 'BASHEOF'
# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# Auto-launch zsh shell if in interactive bash
if command -v zsh &> /dev/null; then
  if [[ $(ps --no-header --pid=$PPID --format=comm) != "zsh" && -z ${BASH_EXECUTION_STRING} && ${SHLVL} == 1 ]]
  then
    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    exec zsh $LOGIN_OPTION
  fi
fi

BASHEOF

    # Append the rest of the existing content (skip interactive check line)
    echo "$EXISTING_BASHRC" | sed '/^\[.*!= \*i\*.*return$/d' >> "${BASHRC}"
    
    echo "✓ Configured bash to auto-launch zsh"
    echo "  (backed up to: ${BASHRC_BACKUP})"
fi

echo "✓ zsh setup complete"
