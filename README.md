# Omarchy Mac (Fedora Asahi)

Omarchy Mac is now targeted at **Fedora Asahi Remix on aarch64** (Apple Silicon).

Unsupported targets:
- Arch / Asahi Alarm
- Non-Asahi Fedora
- x86_64

## Requirements

- Apple Silicon Mac (M1/M2/M3/M4)
- Fedora Asahi Remix Minimal
- Regular user with sudo privileges
- Internet connectivity

## Install

```bash
git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy
bash install.sh
```

The installer now enforces Fedora Asahi aarch64 in preflight checks.

## What Changed

- Installer/runtime/update paths are Fedora-first (`dnf`, `rpm`, `dracut`).
- Arch-only install execution paths were removed from active flow.
- Migration runner skips historical Arch-only migration scripts on Fedora.
- Channel/version scripts no longer depend on `/etc/pacman*`.

## Fedora Minimal Safeguards

- Preflight now validates essential DE/runtime package availability before install continues.
- Login/session startup uses an SDDM-only path on Fedora to avoid tty/session conflicts.
- Installer restores legacy seamless-login changes that can break SDDM autologin on upgraded systems.
- Installer ensures Omarchy command path is available in login shells used by Hyprland sessions.
- Launcher commands include graceful fallbacks for optional tools (`impala`, `bluetui`, `walker`, `hyprlock`).
- Deprecated Arch mirror tooling remains as no-op compatibility stubs on Fedora.

## Runtime Fixes (2026-02-14)

- Resolved Fedora font mismatch by switching default UI/terminal font family references to `JetBrains Mono`.
- Fedora defaults now prioritize Chromium as the system browser (`chromium-browser.desktop` on Fedora).
- Wi-Fi/Bluetooth setup launchers now use robust fallbacks (`impala` -> `nm-connection-editor` -> `nmtui` -> `nmcli` -> `iwctl`, and `bluetui` -> `blueman-manager` -> `bluetoothctl`).
- Webapp launchers now open as separate app windows (`--new-window --app=...`) instead of reusing regular browser tabs.
- Power profile menu now works with wrapper commands and degrades safely when `powerprofilesctl` is missing.
- Media keys now route through `omarchy-media-control`, with fallback control paths when `swayosd-client` is unavailable.
- Launcher keybind reliability was fixed by routing `Super+Space` through `omarchy-launch-walker`, correcting `fuzzel` launch prefix to `uwsm-app --`, and preventing stale `fuzzel --dmenu` lockups.

## Quick Validation

```bash
bash tests/test-fedora-asahi-compatibility.sh
bash install/preflight/fedora-required-pkgs.sh
bash -lc 'command -v chromium-browser nmtui nm-connection-editor blueman-manager bluetoothctl powerprofilesctl'
bash -lc 'xdg-settings get default-web-browser'
```

## Porting and Progress Document

See `FEDORA_ASAHI_PORTING_PLAN.md` for:
- phase-by-phase implementation history,
- completed changes,
- verification runbook,
- remaining backlog.

## Notes for Existing Users

- `fix-mirrors.sh` and `bin/omarchy-refresh-pacman*` are deprecated stubs on Fedora.
- If you previously used Arch-focused branches/workflows, switch to the `fedora` branch.

## Support

- Omarchy Discord: https://omarchy.org/discord
- Omarchy Mac Discord: https://discord.gg/KNQRk7dMzy
