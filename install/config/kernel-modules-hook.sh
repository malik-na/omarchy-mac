# linux-modules-cleanup.service is Arch Linux specific; skip on Fedora
if [[ -f /etc/arch-release ]]; then
  chrootable_systemctl_enable linux-modules-cleanup.service
else
  echo "[SKIP] linux-modules-cleanup.service is Arch-only, skipping on this distro"
fi
