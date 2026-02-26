# Omarchy Mac (Fedora Asahi)

Omarchy Mac is now targeted at **Fedora Asahi Remix on aarch64** (Apple Silicon).

Unsupported targets:
- Arch / Asahi Alarm
- Non-Asahi Fedora
- x86_64

## Requirements

- Apple Silicon Mac (M1/M2)
- Fedora Asahi Remix Minimal
- Regular user with sudo privileges
- Internet connectivity
- `git` installed

## Fedora Minimal Prep (Before Install)

If you are starting from a fresh Fedora Asahi Minimal TTY session, run these steps first.

### 1) Set hostname

```bash
sudo hostnamectl set-hostname your-hostname
```

### 2) Create user, set passwords, and enable sudo

```bash
# Set root password (if not already set)
sudo passwd root

# Create your daily user
sudo useradd -m -G wheel,audio,video,input youruser
sudo passwd youruser

# Ensure wheel has sudo access
sudo bash -lc 'grep -q "^%wheel" /etc/sudoers || echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers'
```

### 3) Set language and keyboard layout

```bash
# Example: US English + US keymap
sudo localectl set-locale LANG=en_US.UTF-8
sudo localectl set-keymap us

# Example alternatives:
# sudo localectl set-locale LANG=de_DE.UTF-8
# sudo localectl set-keymap de
```

### 4) Connect to Wi-Fi with `iwctl`

```bash
iwctl
# inside iwctl:
# device list
# station wlan0 scan
# station wlan0 get-networks
# station wlan0 connect "Your SSID"
# exit
```

### 5) Install Terminus console font and increase TTY font size

```bash
sudo dnf install -y terminus-fonts-console || sudo dnf install -y terminus-fonts

# Try a larger Terminus font immediately in current TTY
sudo setfont ter-v22n

# Persist it across reboots
sudo sed -i 's/^FONT=.*/FONT=ter-v22n/' /etc/vconsole.conf
grep -q '^FONT=' /etc/vconsole.conf || echo 'FONT=ter-v22n' | sudo tee -a /etc/vconsole.conf
```

### 6) Increase desktop terminal font size after install (optional)

```bash
# Alacritty
sed -i 's/^size = .*/size = 11/' ~/.config/alacritty/alacritty.toml

# Kitty
sed -i 's/^font_size .*/font_size        11.0/' ~/.config/kitty/kitty.conf

# Ghostty
sed -i 's/^font-size = .*/font-size = 11/' ~/.config/ghostty/config
```

## Install

```bash
git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy
git checkout fedora
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
- Lock/idle/nightlight stack was repaired by installing `hyprlock`/`hypridle`/`hyprsunset`, fixing autostart behavior, and hardening fallback scripts for screensaver + PATH handling.

## Startup + Config Fixes (2026-02-15)

- Ghostty defaults were corrected for current upstream config validation (removed unsupported `gtk-toolbar-style`, fixed invalid shell integration feature list, and fixed split-resize keybind trigger names).
- Ghostty migration `1763633307.sh` now inserts valid split resize keybinds (`down/up/left/right`) instead of invalid `arrow_*` trigger names.
- Waybar startup in Hyprland was hardened against restricted login `PATH` by launching with an explicit known-good path and fallback (`uwsm-app -- waybar || waybar`).

## Update Behavior

- `omarchy-update` updates both the Omarchy repo and Fedora system packages (`dnf upgrade --refresh`).
- Update availability in Waybar now tracks git branch divergence from the configured upstream branch, not only tags.
- If your branch has no upstream tracking branch, `omarchy-update-available` reports that explicitly.
- To review your current branch and upstream state:

```bash
git -C ~/.local/share/omarchy status -sb
```

## Quick Validation

```bash
bash tests/test-fedora-asahi-compatibility.sh
bash install/preflight/fedora-required-pkgs.sh
bash -lc 'command -v chromium-browser nmtui nm-connection-editor blueman-manager bluetoothctl powerprofilesctl'
bash -lc 'command -v hyprlock hypridle hyprsunset tte'
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

- Omarchy Mac Discord: https://discord.gg/KNQRk7dMzy
