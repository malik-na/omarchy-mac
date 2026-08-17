SNAPPER_CONFIG_PATH="${OMARCHY_SNAPPER_CONFIG_PATH:-/etc/snapper/configs/root}"
SNAPPER_CONF_PATH="${OMARCHY_SNAPPER_CONF_PATH:-/etc/conf.d/snapper}"
template="${OMARCHY_SNAPPER_TEMPLATE:-${OMARCHY_PATH:-/usr/share/omarchy}/default/snapper/root}"

echo "Configuring Omarchy Snapper snapshot retention"

snapper_configured=1

if [[ ! -f $SNAPPER_CONFIG_PATH ]]; then
  mkdir -p "$(dirname "$SNAPPER_CONFIG_PATH")"

  if [[ ${OMARCHY_SNAPPER_CONFIGURE_TEST:-0} == "1" ]]; then
    : >"$SNAPPER_CONFIG_PATH"
  elif ! snapper --no-dbus -c root create-config / >/dev/null 2>&1 &&
    ! snapper -c root create-config / >/dev/null 2>&1; then
    # Snapper needs a snapshot-capable root; Asahi installs land on ext4.
    # Left unhandled this aborts system setup before services are enabled.
    snapper_configured=0
  fi
fi

if (( snapper_configured )); then
  install -m 0644 "$template" "$SNAPPER_CONFIG_PATH"

  mkdir -p "$(dirname "$SNAPPER_CONF_PATH")"
  printf '%s\n' 'SNAPPER_CONFIGS="root"' >"$SNAPPER_CONF_PATH"
  chmod 0644 "$SNAPPER_CONF_PATH"

  systemctl disable --now snapper-timeline.timer >/dev/null 2>&1 || true
  systemctl enable --now snapper-cleanup.timer >/dev/null 2>&1 || true

  # limine-snapper-sync exists only on x86 Limine installs; Macs boot via GRUB.
  if systemctl cat limine-snapper-sync.service >/dev/null 2>&1; then
    systemctl enable --now limine-snapper-sync.service >/dev/null 2>&1 || true
  fi
else
  echo "Skipping Snapper setup: / is not a snapshot-capable filesystem."
fi
