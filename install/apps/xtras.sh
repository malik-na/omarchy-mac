#!/bin/bash

if [ -z "$OMARCHY_BARE" ]; then
  yay -S --noconfirm --needed     gnome-calculator gnome-keyring     libreoffice kdenlive     xournalpp localsend-bin  # Packages known to be flaky or having key signing issues are run one-by-one  for pkg in typora zoom; do    yay -S --noconfirm --needed "$pkg" ||      echo -e "\e[31mFailed to install $pkg. Continuing without!\e[0m"  done
fi

# Copy over Omarchy applications
source ~/.local/share/omarchy/bin/omarchy-refresh-applications || true
