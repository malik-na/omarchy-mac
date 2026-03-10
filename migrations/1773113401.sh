echo "Install and configure zram swap for memory-constrained systems"

if omarchy-pkg-missing zram-generator; then
  omarchy-pkg-add zram-generator
fi

if [[ ! -f /etc/systemd/zram-generator.conf ]]; then
  sudo mkdir -p /etc/systemd
  sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
fi

sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
