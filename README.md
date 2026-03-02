# Omarchy Mac Fedora (Fedora Asahi Remix)

A concise, beginner-friendly guide to install Omarchy Mac on **Fedora Asahi Remix (aarch64)** for Apple Silicon Macs.

_This project is not intended for x86_64 systems, non-Asahi Fedora installs, or virtual machines._

**Important:** Fedora Asahi Minimal first boot lands in a TTY setup flow. You must complete all prompts there before running Omarchy Mac installer steps.

[![License](https://img.shields.io/github/license/malik-na/omarchy-mac)](LICENSE) [![Stars](https://img.shields.io/github/stars/malik-na/omarchy-mac?style=social)](https://github.com/malik-na/omarchy-mac/stargazers)

---

## Quick links

- Fedora Asahi device support: https://asahilinux.org/fedora/#device-support
- Omarchy Mac Discord: https://discord.gg/KNQRk7dMzy
- External monitor discussion: https://github.com/malik-na/omarchy-mac/discussions/73
- Support the project: https://buymeacoffee.com/malik2015no

---

## Table of contents

- [Before you begin](#before-you-begin)
- [Connect to Wi-Fi before installation](#connect-to-wi-fi-before-installation)
- [Quick start](#quick-start)
- [Detailed installation](#detailed-installation)
  - [Prepare Fedora Asahi Minimal](#prepare-fedora-asahi-minimal)
  - [Install Omarchy Mac Fedora](#install-omarchy-mac-fedora)
- [Post-install tasks](#post-install-tasks)
- [Troubleshooting and FAQ](#troubleshooting-and-faq)
- [Update and maintenance](#update-and-maintenance)
- [Migrating from older Arch-based installs](#migrating-from-older-arch-based-installs)
- [Support](#support)
- [External resources](#external-resources)
- [Acknowledgements](#acknowledgements)
- [Contributors](#contributors)

---

## Before you begin

Requirements:

- Apple Silicon Mac (M1/M2 family)
- Fedora Asahi Remix Minimal (aarch64)
- A regular user with sudo access
- Internet connectivity
- `git` installed

Unsupported targets:

- Arch/Asahi Alarm runtime paths
- Non-Asahi Fedora installs
- x86_64

Checklist:

- [ ] Backup completed
- [ ] Fedora Asahi device compatibility checked
- [ ] Fedora Asahi first-boot TTY setup completed (language, hostname, time, root password, user, wheel)
- [ ] Internet connected
- [ ] Sudo user ready

---

## Connect to Wi-Fi before installation

Use one of these methods from your Fedora Asahi session before running the installer.

### Option 1: `nmcli` (NetworkManager CLI)

```bash
# Check network devices
nmcli device status

# Scan and list Wi-Fi networks (replace wlan0 if needed)
nmcli device wifi rescan ifname wlan0
nmcli device wifi list ifname wlan0

# Connect to a network
nmcli device wifi connect "SSID_NAME" password "PASSWORD" ifname wlan0
```

### Option 2: `iwctl` (iwd)

```bash
iwctl
# inside iwctl:
# device list
# station wlan0 scan
# station wlan0 get-networks
# station wlan0 connect "SSID_NAME"
# exit
```

If `wlan0` does not exist on your system, replace it with your detected wireless interface name.

Fedora Asahi Minimal normally includes the required first-boot setup prompts; use these commands only to ensure networking is ready before install.

---

## Quick start

From your Fedora Asahi user session:

```bash
sudo dnf install git
git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy
git checkout fedora
bash install.sh
```

The installer enforces Fedora Asahi aarch64 in preflight checks.

---

## Detailed installation

### Prepare Fedora Asahi Minimal (required)

Fedora Asahi Minimal always starts with a TTY setup flow. Complete all prompts there before continuing:

- language
- hostname
- date/time
- root password
- regular user creation
- wheel/sudo access

Do not continue to Omarchy install until all first-boot setup actions are complete.

Optional: improve TTY readability

```bash
sudo dnf install -y terminus-fonts-console || sudo dnf install -y terminus-fonts
sudo setfont ter-v22n
```

### Install Omarchy Mac Fedora

As your regular sudo user:

```bash
git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy
git checkout fedora
bash install.sh
```

---

## Post-install tasks

- Reboot and log into your Hyprland session.
- Validate core desktop behavior: app launcher opens, terminal keybind works, Wi-Fi/Bluetooth menus open, and lock screen works.

## Troubleshooting and FAQ

### Installer refuses to continue

The installer currently supports **Fedora Asahi Remix on aarch64 only**. Verify distro/architecture and rerun.

### Wi-Fi or Bluetooth tools are missing

Omarchy launchers use Fedora-friendly fallbacks:

- Wi-Fi: `impala` -> `nm-connection-editor` -> `nmtui` -> `nmcli` -> `iwctl`
- Bluetooth: `bluetui` -> `blueman-manager` -> `bluetoothctl`

### Session launches but keybinds fail

Run this to confirm Omarchy commands resolve in your login shell:

```bash
bash -lc 'echo "$PATH"'
bash -lc 'command -v omarchy-menu omarchy-cmd-terminal-cwd uwsm-app'
```

For implementation and runtime hardening details, see `FEDORA_ASAHI_PORTING_PLAN.md`.

---

## Update and maintenance

- `omarchy-update` updates both the Omarchy repository and Fedora system packages (`dnf upgrade --refresh`).
- Waybar update indicators track git divergence from your configured upstream branch.

Check branch/upstream state:

```bash
git -C ~/.local/share/omarchy status -sb
```

---

## Support

Need help or want to share your setup?

- Discord: https://discord.gg/KNQRk7dMzy
- Support: https://buymeacoffee.com/malik2015no

---

## External resources

- Fedora Asahi device support: https://asahilinux.org/fedora/#device-support
- Asahi Linux project: https://asahilinux.org/
- External monitor discussion: https://github.com/malik-na/omarchy-mac/discussions/73

---

## Acknowledgements

Thanks to the Asahi Linux community and DHH for Omarchy.

If this project helped you, please star the repository and share feedback in issues/discussions.

---

## Contributors

See the full contributors list here:

https://github.com/malik-na/omarchy-mac/graphs/contributors
