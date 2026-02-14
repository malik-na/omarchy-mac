#!/bin/bash
# Copy over Omarchy configs
mkdir -p ~/.config
cp -R ~/.local/share/omarchy/config/* ~/.config/

# Use default bashrc from Omarchy
cp ~/.local/share/omarchy/default/bashrc ~/.bashrc

# Ensure Omarchy commands are available in login sessions (e.g. SDDM Wayland).
if ! grep -q 'OMARCHY_PATH="$HOME/.local/share/omarchy"' ~/.profile 2>/dev/null; then
  cat >>~/.profile <<'EOF'

export OMARCHY_PATH="$HOME/.local/share/omarchy"
export PATH="$OMARCHY_PATH/bin:$PATH"
EOF
fi

# Ensure user-local pip/npm tools are available as well.
if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' ~/.profile 2>/dev/null; then
  cat >>~/.profile <<'EOF'
export PATH="$HOME/.local/bin:$PATH"
EOF
fi

# Ensure bash login shells (used by SDDM session wrapper) load ~/.profile.
if ! grep -q 'if \[ -f ~/.profile \ ]; then' ~/.bash_profile 2>/dev/null; then
  cat >>~/.bash_profile <<'EOF'

if [ -f ~/.profile ]; then
    . ~/.profile
fi
EOF
fi
