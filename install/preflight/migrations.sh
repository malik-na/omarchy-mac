#!/bin/bash
OMARCHY_MIGRATIONS_STATE_PATH=~/.local/state/omarchy/migrations
mkdir -p $OMARCHY_MIGRATIONS_STATE_PATH
mkdir -p "$OMARCHY_MIGRATIONS_STATE_PATH/skipped"

is_arch_only_migration() {
  local file="$1"
  grep -Eq "\\bpacman\\b|\\byay\\b|\\bparu\\b|/etc/pacman|mkinitcpio|limine|pacman-key|omarchy-refresh-pacman|linux-asahi|install/config/hardware/(fix-fkeys|intel|nvidia|fix-surface-keyboard|fix-bcm43xx|fix-apple-t2|fix-apple-spi-keyboard|fix-apple-bcm43xx|fix-apple-bcm4360|fix-apple-suspend-nvme)\\.sh" "$file"
}

for file in ~/.local/share/omarchy/migrations/*.sh; do
  if is_arch_only_migration "$file"; then
    touch "$OMARCHY_MIGRATIONS_STATE_PATH/skipped/$(basename "$file")"
  else
    touch "$OMARCHY_MIGRATIONS_STATE_PATH/$(basename "$file")"
  fi
done
