# Fedora Asahi Porting Plan and Progress

Date: 2026-02-14
Target: Fedora Asahi Remix on aarch64 (Fedora Minimal base)
Scope: `omarchy-mac` only supports Fedora Asahi aarch64. Arch/Asahi Alarm is no longer a supported runtime path.

## Goals

- Make install and runtime reliable on Fedora Asahi Minimal.
- Remove active Arch-only execution paths from installer/update/runtime workflows.
- Keep migration and update behavior safe when old Arch-oriented scripts still exist in the repository.

## Phase Status

- Phase 1 (install blockers): completed
- Phase 2 (first-run/runtime parity): completed
- Phase 3 (updates/migrations hardening): completed

## Implemented Changes

### Phase 1 - Install Blockers (Completed)

- Fedora-only gating and branch selection:
  - `boot.sh`
  - `install.sh`
  - `install/preflight/guard.sh`
- Removed Arch-only install execution paths:
  - `install/preflight/all.sh`
  - `install/packaging/all.sh`
  - `install/login/all.sh`
  - `install/post-install/all.sh`
- Fedora-safe package helper baseline:
  - `install/helpers/packages.sh` (rewritten for Fedora-only behavior)
  - `install/helpers/distro.sh`
  - `bin/omarchy-pkg-add`
- First-run firewall/sudoers conversion from UFW to firewalld:
  - `install/preflight/first-run-mode.sh`
  - `install/first-run/firewall.sh`
  - `bin/omarchy-cmd-first-run`
- Guarded optional components and theme paths to avoid hard failures on minimal systems:
  - `install/first-run/elephant.sh`
  - `install/first-run/gnome-theme.sh`
  - `install/config/theme.sh`
  - `install/config/hardware/network.sh`
  - `install/config/hardware/keyboard-backlight.sh`
  - `install/config/hardware/set-wireless-regdom.sh`
  - `install/helpers/presentation.sh`

### Phase 2 - Runtime Parity on Fedora Minimal (Completed)

- Fedora-native update flow:
  - `bin/omarchy-update-system-pkgs` (DNF upgrade + autoremove)
  - `bin/omarchy-update-perform` (RPM kernel version snapshot)
  - `bin/omarchy-update-restart` (RPM kernel comparison)
- Fedora package utility conversion:
  - `bin/omarchy-pkg-install`
  - `bin/omarchy-pkg-remove`
  - `bin/omarchy-pkg-drop`
  - `bin/omarchy-pkg-present`
  - `bin/omarchy-pkg-missing`
  - `bin/omarchy-pkg-aur-install` (redirect to Fedora repo install)
  - `bin/omarchy-pkg-aur-accessible` (disabled on Fedora)
- Menu install actions switched away from pacman/yay:
  - `bin/omarchy-menu`
- Fedora minimal prerequisites added to base package list:
  - `install/omarchy-base.packages.fedora` (`firewalld`, `python3-pip`, `flatpak`)
- Dev environment installer update for Fedora PHP stack:
  - `bin/omarchy-install-dev-env`

### Phase 3 - Migration and Update Hardening (Completed)

- Distro-safe migrations:
  - `bin/omarchy-migrate`
    - Detects Arch-only migrations by pattern and skips them on Fedora.
    - Records skipped migrations under `~/.local/state/omarchy/migrations/skipped`.
  - `install/preflight/migrations.sh`
    - Initializes migration state and classifies historical Arch-only migrations as skipped on fresh install.
- Fedora-safe channel/version scripts:
  - `bin/omarchy-branch-set` (adds `fedora` branch support)
  - `bin/omarchy-channel-set` (no pacman repo refresh; persists channel state)
  - `bin/omarchy-version-channel` (reads state/git branch, no `/etc/pacman*`)
  - `bin/omarchy-version-pkgs` (reads DNF history instead of `pacman.log`)
  - `bin/omarchy-update-keyring` (explicit Fedora no-op)

## Progress Summary

- Installer flow is now Fedora Asahi aarch64 constrained.
- Critical first-run failures from UFW/pacman assumptions are removed.
- Runtime package and update commands are DNF/RPM based.
- Migration execution is protected from historical Arch-only migration scripts.
- Channel/version reporting no longer depends on pacman files.

## Verification Runbook

- Syntax checks:
  - `bash -n boot.sh install.sh`
  - `bash -lc 'for f in bin/* install/**/*.sh; do bash -n "$f" || echo "SYNTAX_ERROR $f"; done'`
- Fedora guard check:
  - `bash install/preflight/guard.sh`
- Spot-check removed Arch assumptions in hardened scripts:
  - `rg -n "pacman|yay|paru|/etc/pacman|pacman.log|pacman-key" bin/omarchy-migrate bin/omarchy-channel-set bin/omarchy-version-channel bin/omarchy-version-pkgs bin/omarchy-update-keyring`

## Remaining TODOs

- Completed: removed inactive Arch-only install/login/preflight scripts from active repository paths.
- Completed: replaced README with Fedora Asahi-only installation and support policy.
- Completed: added Fedora compatibility smoke test at `tests/test-fedora-asahi-compatibility.sh`.
- P1 (high): add end-to-end Fedora minimal integration test run (install + first-run + update + migrate).
- P2 (medium): verify every optional menu installer target resolves to a Fedora package or has a graceful fallback.
- P3 (low): continue pruning historical Arch-only docs that are kept only for archive context.

## Notes

- This document tracks execution-level changes already applied in the repository.
- Future work should keep Fedora Asahi aarch64 as the only supported environment unless project direction changes.

## Package Availability Validation (2026-02-14)

- Base package set in `install/omarchy-base.packages.fedora` validated against current Fedora repositories:
  - Total: 61
  - Missing: 0
- Fix applied:
  - Replaced `jetbrains-mono-nf-fonts` with `jetbrains-mono-fonts`.
- Manual install path validation:
  - `lazydocker` URL generation fixed to use versioned GitHub release assets.
  - `uwsm` installation path was tested and later removed from required/automatic install flow after Fedora 42 package/source issues.
  - `terminaltexteffects` PyPI endpoint reachable.
  - Flatpak IDs for Typora and LocalSend validated on flathub.
  - `swayosd` remains repository-dependent; installer now checks availability before install and skips cleanly when unavailable.

## Fedora Minimal DE Hardening (2026-02-14)

- Added preflight guard for essential DE package availability:
  - `install/preflight/fedora-required-pkgs.sh`
  - wired into `install/preflight/all.sh`
- Added `lxpolkit` to Fedora package list and guarded desktop startup paths:
  - `install/omarchy-base.packages.fedora`
  - `default/hypr/autostart.conf`
- Added runtime fallback wrapper for `uwsm-app` to avoid launcher breakage when UWSM helper is absent:
  - `bin/uwsm-app`
- Improved login/session resilience:
  - `install/login/sddm.sh` picks `hyprland` session when `hyprland-uwsm.desktop` is unavailable.
  - `install/login/plymouth.sh` uses `uwsm start -- hyprland.desktop` only when `uwsm` exists; otherwise starts `hyprland` directly.
- Added command fallbacks for missing optional TUI launchers:
  - `bin/omarchy-launch-wifi` (impala -> nm-connection-editor -> nmtui)
  - `bin/omarchy-launch-bluetooth` (bluetui -> blueman-manager -> bluetoothctl)
  - `bin/omarchy-launch-walker` (walker -> fuzzel fallback)
  - `bin/omarchy-lock-screen` (hyprlock -> loginctl)

## Session Reliability Fixes (2026-02-14)

- Root causes confirmed on target Fedora Asahi machine:
  - `sddm` and `omarchy-seamless-login` were enabled at the same time, causing tty/session contention.
  - `uwsm` was unavailable from enabled repositories, and pip/git fallback install path failed.
  - PATH for login sessions did not consistently include `~/.local/share/omarchy/bin`, which broke most Hyprland keybind commands.
- Fixes applied:
  - `install/login/all.sh` switched to SDDM-only login path on Fedora (no seamless-login execution in active flow).
  - `install/login/sddm.sh` now disables/removes legacy seamless-login units and restores `getty@tty1`.
  - `install/preflight/dnf.sh` now enables required COPR repositories in all install modes.
  - `install/omarchy-base.packages.fedora` no longer requires `uwsm`.
  - `install/helpers/fedora-manual.sh` no longer attempts broken automatic `uwsm` installation.
  - `install/config/config.sh` now ensures login shells source profile exports so Omarchy commands are available in Hyprland binds.

## Runtime Parity Fixes (2026-02-14)

- Root causes confirmed on target machine after Hyprland became boot-stable:
  - Font rendering mismatched because config used `JetBrainsMono Nerd Font` while Fedora package provides `JetBrains Mono`.
  - Browser and webapp launchers assumed Chromium desktop entries in some paths.
  - TUI launch path argument handling caused Wi-Fi/Bluetooth fallback launch failures.
  - Setup menu still called legacy `blueberry` binary.
  - Power profile menu failed when `powerprofilesctl` command was unavailable.
  - Media/brightness binds depended on `swayosd-client` only.
  - App launcher/menu keybind path regressed because `Super+Space` directly invoked `fuzzel` and fallback `fuzzel --dmenu` could remain locked.
- Fixes applied:
  - Font family defaults updated to `JetBrains Mono` across terminal/UI/fontconfig defaults and migration helper.
  - Browser MIME/default setup now chooses first available supported browser desktop entry.
  - `omarchy-launch-browser` and `omarchy-launch-webapp` now resolve browser executables dynamically with robust fallbacks.
  - `omarchy-launch-tui` and `omarchy-launch-or-focus-{tui,webapp}` now quote/forward arguments safely.
  - `omarchy-launch-wifi` fallback chain expanded to include `nmcli` and `iwctl`.
  - `omarchy-menu` setup Bluetooth action now uses `omarchy-launch-bluetooth`.
  - Added `omarchy-powerprofiles-get` and `omarchy-powerprofiles-set`; menu now uses wrappers.
  - Added `omarchy-media-control` and switched default Hypr media binds to wrapper-based control paths.
  - `Super+Space` now uses `omarchy-launch-walker` wrapper in defaults and user bindings.
  - Fixed fuzzel launcher config to use `launch-prefix=uwsm-app --`.
  - Updated walker fallback to avoid non-interactive `fuzzel --dmenu` lockups and added clipboard-mode fallback behavior.
  - Fedora package baseline updated to include: `firefox`, `power-profiles-daemon`, `NetworkManager-tui`, `nm-connection-editor`, `blueman`.
- Verification completed on target Fedora Asahi machine:
  - Script syntax checks passed for updated launcher/control scripts.
  - `tests/test-fedora-asahi-compatibility.sh` passed.
  - Verified commands present: `nmtui`, `nm-connection-editor`, `blueman-manager`, `bluetoothctl`, `powerprofilesctl`, `firefox`.
  - Verified browser default: `org.mozilla.firefox.desktop`.
  - Verified power profile wrappers and `powerprofilesctl` set/get flow.

## Required Next Steps (Root Session)

- Run these installer steps with root-capable sudo session on target machine:
  - `bash install/preflight/dnf.sh`
  - `bash install/login/sddm.sh`
  - `bash install/config/config.sh`
- Reboot after scripts complete:
  - `sudo reboot`
- Post-reboot verification checklist:
  - `systemctl is-enabled sddm.service` -> `enabled`
  - `systemctl is-enabled omarchy-seamless-login.service` -> `disabled` or `not-found`
  - `journalctl -b -u sddm.service --no-pager -n 120` -> no `Failed to take control of "/dev/tty1"`
  - `bash -lc 'echo "$PATH"'` -> includes `~/.local/share/omarchy/bin`
  - `bash -lc 'command -v omarchy-menu omarchy-cmd-terminal-cwd uwsm-app'`
- Functional desktop checks in Hyprland session:
  - `SUPER+RETURN` opens terminal
  - app launcher opens and launches apps
  - no blank session with non-working keybinds
