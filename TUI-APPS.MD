# TUI Apps (Fedora / Asahi)

This document describes Omarchy TUI apps used in Fedora workflows, where they come from, how they are installed, and how they are launched.

## Scope

The Fedora helper currently manages:

- `bluetui`
- `impala`
- `wiremix`

Helper entrypoint:

- `install/helpers/fedora-rust-tuis.sh`

Packaging integration:

- `install/packaging/all.sh`

## Install Strategy

Order used by the helper:

1. Detect Fedora (`helpers/distro.sh`)
2. Ensure `bluetui` from repositories / COPR fallback
3. Ensure `iwd` backend for NetworkManager (required for stable `impala` usage)
4. Ensure Rust toolchain (`rustc`, `cargo`)
5. Ensure `wiremix` build dependency (`pipewire-devel`)
6. Install Cargo apps with pinned versions (`--locked --version`)
7. Symlink Cargo binaries to `~/.local/bin`

## App Details

### bluetui

Purpose:

- Bluetooth terminal UI.

Primary source:

- Fedora repositories when available.

Fallback source:

- COPR `nclundell/fedora-extras`
- On Fedora Asahi Remix 42 aarch64, helper attempts COPR chroot `fedora-43-aarch64` first.

Expected binary:

- `bluetui`

Verification:

- `rpm -q bluetui`
- `command -v bluetui`

### impala

Purpose:

- Wi-Fi terminal UI used by Omarchy Wi-Fi launcher.

Source:

- Cargo crate install (no reliable Fedora package in this target environment).

Pinned version:

- `0.7.3`

Install command style:

- `cargo install --locked impala --version 0.7.3`

Expected binary locations:

- `~/.cargo/bin/impala`
- `~/.local/bin/impala` (symlink created by helper)

Critical runtime requirement:

- `iwd` backend active with NetworkManager (`wifi.backend=iwd`).
- Without `iwd`, `impala` may open and exit immediately.

### wiremix

Purpose:

- Audio terminal UI.

Source:

- Cargo crate install.

Pinned version:

- `0.9.0`

Install command style:

- `cargo install --locked wiremix --version 0.9.0`

Build dependency:

- `pipewire-devel`

Expected binary locations:

- `~/.cargo/bin/wiremix`
- `~/.local/bin/wiremix` (symlink created by helper)

## Wi-Fi Launcher Behavior

File:

- `bin/omarchy-launch-wifi`

Behavior:

1. `rfkill unblock wifi` (best effort)
2. If `iwd` is active and `impala` exists -> launch `impala`
3. Else fallback to `nmtui`
4. Then `nm-connection-editor`
5. Then `nmcli device wifi`
6. Then `iwctl` (only when `iwd` is active)

This avoids unstable `impala` launches on `wpa_supplicant` systems.

## Operational Notes

- Helper is Fedora-only and no-op on non-Fedora distros.
- Cargo installs are best-effort; helper prints warnings but continues.
- `~/.local/bin` is ensured for user-level command discovery.

## Troubleshooting

### impala opens then closes

Check backend:

- `systemctl is-active iwd`
- `systemctl is-active wpa_supplicant`
- `grep -RIn "wifi.backend" /etc/NetworkManager`

Expected healthy state:

- `iwd` active
- `wpa_supplicant` inactive
- NetworkManager config includes `wifi.backend=iwd`

### command not found from launcher

Check binary resolution:

- `command -v impala`
- `command -v wiremix`
- `ls -l ~/.local/bin/impala ~/.local/bin/wiremix`

### Cargo install failed

Check toolchain and deps:

- `rustc --version`
- `cargo --version`
- `rpm -q pipewire-devel`

Retry manually:

- `cargo install --locked impala --version 0.7.3`
- `cargo install --locked wiremix --version 0.9.0`

## Maintenance

When updating versions:

1. Update pinned versions in `install/helpers/fedora-rust-tuis.sh`
2. Validate builds on Fedora Asahi Remix target
3. Verify launchers (`omarchy-launch-wifi`, waybar click actions)
4. Update this document version section and troubleshooting notes
