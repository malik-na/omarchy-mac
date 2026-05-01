echo "Enable Intel LPMD service if installed"

if omarchy-hw-intel && pacman -Q intel-lpmd &>/dev/null; then
  sudo systemctl enable --now intel_lpmd.service
fi
