#!/bin/bash
if ! command -v firewall-cmd >/dev/null 2>&1; then
  echo "[WARN] firewalld is not available; skipping firewall setup"
  exit 0
fi

if ! systemctl is-enabled firewalld >/dev/null 2>&1; then
  sudo systemctl enable --now firewalld
fi

# LocalSend discovery and transfer ports
sudo firewall-cmd --permanent --add-port=53317/udp
sudo firewall-cmd --permanent --add-port=53317/tcp

# Allow Docker containers to use DNS on host bridge
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="172.16.0.0/12" destination address="172.17.0.1" port protocol="udp" port="53" accept'

sudo firewall-cmd --reload
