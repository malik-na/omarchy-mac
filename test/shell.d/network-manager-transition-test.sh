#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

dns="$ROOT/bin/omarchy-dns"
hardware_network="$ROOT/install/hardware/network.sh"
migration="$ROOT/migrations/1782002156.sh"

! grep -F 'systemd-networkd' "$dns" >/dev/null || fail "omarchy-dns no longer restarts systemd-networkd"
grep -F 'NetworkManager/conf.d/20-omarchy-dns.conf' "$dns" >/dev/null
grep -F '[global-dns-domain-*]' "$dns" >/dev/null
grep -F 'ipv4.ignore-auto-dns yes' "$dns" >/dev/null
grep -F 'ipv4.ignore-auto-dns no' "$dns" >/dev/null
grep -F 'nmcli device reapply' "$dns" >/dev/null
grep -F 'nmcli general reload conf' "$dns" >/dev/null
grep -F 'nmcli general reload dns-full' "$dns" >/dev/null
if grep -F 'nmcli general reload conf,dns-full' "$dns" >/dev/null; then
  fail "omarchy-dns must not push DNS before reapplying active profiles"
fi
pass "omarchy-dns configures DNS through NetworkManager"

grep -F 'systemd-networkd.service' "$hardware_network" >/dev/null
grep -F 'systemd-networkd.socket' "$hardware_network" >/dev/null
grep -F '20-wlan.network' "$hardware_network" >/dev/null
grep -F 'omarchy-networkd-retired' "$hardware_network" >/dev/null
pass "hardware setup retires archinstall networkd state"

grep -F 'OMARCHY_UPGRADE_TO_QUATTRO_LIVE' "$migration" >/dev/null
grep -F 'systemctl disable --now "$unit"' "$migration" >/dev/null
grep -F 'systemctl stop systemd-networkd.service' "$migration" >/dev/null
grep -F 'NetworkManager.service' "$migration" >/dev/null
grep -F '20-wlan.network' "$migration" >/dev/null
pass "migration repairs upgraded systems with networkd still active"

# enable-services.sh switches DNS to systemd-resolved, but resolv.conf still
# names whatever resolver the machine was installed with, so a fresh install
# reboots unable to resolve a hostname. The Quattro upgrade already links it.
grep -F 'ln -sfn ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf' "$ROOT/install/hardware/network.sh" >/dev/null ||
  fail "hardware setup points resolv.conf at the systemd-resolved stub"
grep -F 'systemctl enable systemd-resolved.service' "$ROOT/install/config/enable-services.sh" >/dev/null ||
  fail "system setup enables the resolver resolv.conf now points at"
pass "fresh installs resolve hostnames after reboot"

# Asahi Alarm configures NetworkManager to drive Wi-Fi through iwd, so disabling
# iwd without moving the backend leaves NetworkManager with no Wi-Fi devices at
# all - the radio simply disappears on a fresh install.
network_setup="$ROOT/install/hardware/network.sh"
grep -F 'systemctl disable iwd.service' "$network_setup" >/dev/null ||
  fail "hardware setup retires iwd"
grep -F 'NetworkManager/conf.d' "$network_setup" >/dev/null ||
  fail "hardware setup moves the NetworkManager Wi-Fi backend off iwd"
grep -F 'wpa_supplicant' "$network_setup" >/dev/null ||
  fail "hardware setup hands Wi-Fi to wpa_supplicant, as the brcmfmac quirk assumes"
pass "retiring iwd moves NetworkManager onto a backend that is still running"
