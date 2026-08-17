# Configure pacman after package installation completes. Offline target package
# installs use the live ISO's offline pacman.conf until this final restore.
cp -f "$OMARCHY_PATH/default/pacman/pacman-${OMARCHY_MIRROR:-stable}.conf" /etc/pacman.conf
# Overwriting the mirrorlist throws away the Asahi Alarm mirrors the machine
# was installed with, leaving one slow generic server. Keep what is there and
# append ours only where it is missing, as omarchy-refresh-pacman-mirrorlist does.
if [[ -s /etc/pacman.d/mirrorlist ]] && grep -qE '^[[:space:]]*Server[[:space:]]*=' /etc/pacman.d/mirrorlist; then
  while read -r mirror; do
    grep -qxF "$mirror" /etc/pacman.d/mirrorlist || printf '%s\n' "$mirror" >>/etc/pacman.d/mirrorlist
  done < <(grep -E '^[[:space:]]*Server[[:space:]]*=' "$OMARCHY_PATH/default/pacman/mirrorlist-${OMARCHY_MIRROR:-stable}")
else
  cp -f "$OMARCHY_PATH/default/pacman/mirrorlist-${OMARCHY_MIRROR:-stable}" /etc/pacman.d/mirrorlist
fi

# Every pacman.conf variant here Includes the asahi-alarm mirrorlist, so ship it
# with them. Without the file pacman refuses to parse its config at all, which
# breaks every later package operation on the installed system.
if [[ -f $OMARCHY_PATH/default/pacman/mirrorlist.asahi-alarm ]]; then
  cp -f "$OMARCHY_PATH/default/pacman/mirrorlist.asahi-alarm" /etc/pacman.d/mirrorlist.asahi-alarm
fi

# omarchy-settings skips this override until cups-browsed is actually present
# to avoid pacman creating cups-browsed.conf.pacnew during ISO package install.
if [[ -f $OMARCHY_PATH/etc-overrides/cups-cups-browsed.conf && -d /etc/cups ]]; then
  cp -f "$OMARCHY_PATH/etc-overrides/cups-cups-browsed.conf" /etc/cups/cups-browsed.conf
  rm -f /etc/cups/cups-browsed.conf.pacnew
fi

source "$OMARCHY_INSTALL/hardware/pacman.sh"
