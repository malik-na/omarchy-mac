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
- Login/session startup now falls back safely when UWSM-specific desktop entries are missing.
- Launcher commands include graceful fallbacks for optional tools (`impala`, `bluetui`, `walker`, `hyprlock`).
- Deprecated Arch mirror tooling remains as no-op compatibility stubs on Fedora.

## Quick Validation

```bash
bash tests/test-fedora-asahi-compatibility.sh
bash install/preflight/fedora-required-pkgs.sh
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
