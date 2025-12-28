
![IMG_5776](https://github.com/user-attachments/assets/86b2651c-4b49-4ec5-ae78-023b01e46a15)

# Omarchy Mac installation steps (_Dual Boot_)

_Disclaimer: This guide is for Apple Silicon Macs (M1/M2). Follow the instructions carefully to avoid bricking your Mac or getting stuck in a boot loop. A fix for boot loop recovery is provided at the end._

## Step 1: Install Arch minimal from Asahi Alarm

Visit [https://asahi-alarm.org/](https://asahi-alarm.org/) and run the following script in your Terminal to start Asahi Alarm Installer:

```bash
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

Once inside the Asahi Alarm Installer, follow the on-screen instructions carefully. A few recommendations:

- You should have at least `50 GB` available on your SSD for the Linux partition.
- Choose `Asahi Arch Minimal` from the list of OS options the installer provides.

## Step 2: Initial Arch Linux Setup

After installation, boot into Arch Linux and perform the initial setup:

1. **Log into root** - username and password: `root`
2. **Configure wifi** - Run `nmtui` for network setup (if you get an error after activating your wifi, reboot)
3. **Update system** - Run `pacman -Syu`
4. **Install essential packages** - Run `pacman -S sudo git base-devel chromium`
5. **Set locale** - Run `nano /etc/locale.gen` and uncomment `en_US.UTF-8`, save and exit.
Run `locale-gen`, then `nano /etc/locale.conf` and verify it shows `LANG=en_US.UTF-8`. If it doesn't, change it to `LANG=en_US.UTF-8`.
Run `locale` and then `reboot`.

## Step 3: Create User Account

Create a new user account and configure sudo access:

1. **Create user** - `useradd -m -G wheel <username>`
2. **Set password** - `passwd <username>`
3. **Configure sudo** - `EDITOR=nano visudo`
4. **Enable wheel group** - Uncomment `%wheel ALL=(ALL:ALL) ALL`
   - For unattended installation, uncomment `%wheel ALL=(ALL:ALL) NOPASSWD: ALL` instead (no password prompts during install)
5. **Save and exit** - Ctrl O, Enter, Ctrl X
6. **Switch to new user** - `su - <username>`

## Step 4: Install AUR Helper and Omarchy Mac

As your new user, set up the AUR helper and install Omarchy Mac:

1. **Install yay AUR helper**:
   ```bash
   git clone https://aur.archlinux.org/yay.git
   cd yay
   makepkg -si
   ```

2. **Clone and setup Omarchy Mac**:
   ```bash
   git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
   cd ~/.local/share/omarchy
   bash install.sh
   ```

   Wait for the installation to complete and enter your password when prompted.

**Note**: If mirrors break during installation, run `bash fix-mirrors.sh` then run `install.sh` again.


### External Monitor [Guide](https://github.com/malik-na/omarchy-mac/discussions/73) ❗

## Omarchy Mac Menu

Omarchy Mac includes the **Omarchy Mac Menu** by default, which replaces Walker with fuzzel for better aarch64 compatibility and performance. The menu system uses fuzzel as the frontend while maintaining all original functionality.

Key improvements:
- Better performance on aarch64 systems (Apple Silicon Macs)
- Fuzzel-based frontend for improved stability
- All original omarchy menu functionality preserved
- Automatic migration from walker-based setup


## Mirrorlist updates

Omarchy may provide a recommended mirrorlist during install, but it will not silently overwrite an existing system mirrorlist.

To force a full overwrite, run the helper with `--force` and/or `--backup` to keep a timestamped backup, or set the environment variable `OMARCHY_FORCE_MIRROR_OVERWRITE=1` during install.

## Changes since v0.1.0

Notable improvements since v0.1.0 that make installation and first-run smoother on Apple Silicon systems:

- ARM mirror enhancements
   - Auto-detects country (from timezone) and tests mirrors before applying.
   - Supports many more regional mirrors with primary/fallback entries and connectivity checks.
   - Runs automatically during the Omarchy preflight on aarch64 systems and creates backups by default.
   - Files: `install/helpers/set-arm-mirrors.sh`, `install/preflight/arm-mirrors.sh`, `install/preflight/all.sh`, `install/helpers/all.sh`.

- Timezone detection & setup
   - Automatic timezone detection (IP-based via `tzupdate`) with confirmation and graceful fallbacks.
   - Interactive/manual selection, first-run reminders, and Waybar/menu integration for easy updates.
   - New commands: `bin/omarchy-cmd-tzupdate-enhanced`, `bin/omarchy-cmd-tzupdate-manual`.
   - Files: `install/config/timezone-detection.sh`, `install/first-run/timezone.sh`, `install/config/timezones.sh`, and related menu/waybar wiring.

- Menu & UX
   - The Omarchy Mac Menu has moved to a `fuzzel` frontend for improved aarch64 stability and performance.
   - Menu now exposes timezone and update helpers for easier access.

- Mirrorlist & safety
   - The installer merges recommended servers into existing `/etc/pacman.d/mirrorlist` by default and only overwrites when explicitly requested (or when `OMARCHY_FORCE_MIRROR_OVERWRITE=1` is set).
   - A `fix-mirrors.sh` helper is available to repair mirror issues during install.

These changes preserve existing workflows while improving reliability for new installs.

## Boot Loop Recovery

If you end up in a boot loop:

1. Don't panic.
2. Follow this guide: [https://support.apple.com/en-us/108900](https://support.apple.com/en-us/108900)

---

New updates coming soon...

### If you enjoy __Omarchy Mac__, please give it a star and share your experience on Twitter/X by tagging me [@tiredkebab](https://x.com/tiredkebab)

Join [Omarchy Mac Discord server](https://discord.gg/KNQRk7dMzy) for updates and support.

- Consider supporting: [![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/malik2015no)

## Acknowledgements
- Thanks to [Asahi Linux](https://asahilinux.org/) and [Asahi Alarm](https://asahi-alarm.org/) for making Linux possible on M1/M2 Macs
- Thanks to [DHH](https://github.com/dhh) for creating Omarchy

## Contributors

- Thank you [IvanKurbakov](https://github.com/tayowrld) for making [Omarchy Mac Menu](https://github.com/tayowrld/omarchy-mac-menu)
