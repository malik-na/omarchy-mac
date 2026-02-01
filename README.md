A screenshot to help identify the project:

![IMG_5776](https://github.com/user-attachments/assets/86b2651c-4b49-4ec5-ae78-023b01e46a15)

# Omarchy Mac — Dual Boot Installation
A concise, beginner-friendly guide to install Omarchy Mac (Asahi Alarm + Omarchy) alongside macOS on Apple Silicon (M1/M2).

[![License](https://img.shields.io/github/license/malik-na/omarchy-mac)](LICENSE) [![Stars](https://img.shields.io/github/stars/malik-na/omarchy-mac?style=social)](https://github.com/malik-na/omarchy-mac/stargazers)

---

## Quick links

- Start installer — `curl https://asahi-alarm.org/installer-bootstrap.sh | sh`
- External monitor guide — https://github.com/malik-na/omarchy-mac/discussions/73
- Support — https://buymeacoffee.com/malik2015no
- Discord — https://discord.gg/KNQRk7dMzy

---

## Table of contents

- [Before you begin](#before-you-begin)
- [Quick start](#quick-start)
- [Detailed installation](#detailed-installation)
  - [Run Asahi Alarm](#run-asahi-alarm)
  - [Initial Arch setup](#initial-arch-setup)
  - [Create a regular user](#create-a-regular-user)
  - [Install yay and Omarchy Mac](#install-yay-and-omarchy-mac)
- [Post‑install tasks](#post-install-tasks)
- [Troubleshooting & FAQ](#troubleshooting--faq)
- [Removal (uninstall)](#removal-uninstall)
- [Support](#support)
- [External resources](#external-resources)
- [Acknowledgements](#acknowledgements)
- [Omarchy Mac Contributors](#omarchy-mac-contributors)

---

## Before you begin

Ensure the following before starting:

- A recent backup of macOS (Time Machine or similar).
- An Apple Silicon Mac (M1/M2 family). Verify compatibility: https://asahilinux.org/fedora/#device-support
- At least 50 GB free on the internal SSD (100 GB recommended).
- Internet access.

Checklist

- [ ] Backup completed
- [ ] Sufficient disk space
- [ ] Internet connected

---

## Quick start

Run the Asahi Alarm installer from macOS Terminal and follow the UI.

```bash
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

Select `Asahi Arch Minimal`. When the installer finishes and you boot into Arch, continue with the detailed instructions below.

---

## Detailed installation

Follow these steps after the installer has finished and you have booted into the new Arch system.

### Run Asahi Alarm

- From macOS Terminal run the quick start command above.
- In the installer choose `Asahi Arch Minimal` and allocate at least 50 GB for Linux.

### Initial Arch setup

Run these commands (replace placeholders where indicated):

```bash
# Configure Wi‑Fi (if required)
nmtui

# Update packages
sudo pacman -Syu

# Install essential packages
sudo pacman -S --needed sudo git base-devel chromium

# Enable en_US.UTF-8 locale
sudo nano /etc/locale.gen   # uncomment en_US.UTF-8
sudo locale-gen
echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf
locale

# Reboot to apply changes
sudo reboot
```

Notes

- If `nmtui` shows an error after activation, reboot and try again.
- Use `--needed` to avoid reinstalling packages that already exist.

### Create a regular user

Create a non‑root user and enable sudo for the wheel group:

```bash
# Replace <username> with your chosen name
sudo useradd -m -G wheel <username>
sudo passwd <username>

# Enable wheel in sudoers
sudo EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL

# Switch to your user
su - <username>
```

Unattended installs: you may use `NOPASSWD:` for wheel, but this reduces security.

### Install yay and Omarchy Mac

As the non‑root user:

```bash
# Install yay (AUR helper)
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Clone and run Omarchy Mac installer
git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy
bash install.sh
```

- Enter your password when prompted and follow the installer's prompts.
- If mirrors fail, run `bash fix-mirrors.sh` from the repository root and retry.

---

## Post-install tasks

- Reboot and select the Linux entry.
- Verify display, keyboard, touchpad, Wi‑Fi, and external monitor support.

---

## Troubleshooting & FAQ

### I lost network during install

1. Try the interactive UI: `nmtui`.
2. If that fails, use NetworkManager CLI:

```bash
nmcli device status
nmcli device wifi list ifname wlan0
nmcli device wifi connect "SSID_NAME" password "PASSWORD" ifname wlan0
sudo systemctl restart NetworkManager
sudo journalctl -u NetworkManager -b
```

Replace `wlan0` with your wireless device name. Inspect `sudo journalctl -u NetworkManager -b` and `/var/log/pacman.log` for clues.

### Mirrors are slow or failing

1. Run the helper: `bash fix-mirrors.sh` and retry.
2. Manually edit `/etc/pacman.d/mirrorlist` if needed:

```bash
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
sudo nano /etc/pacman.d/mirrorlist
# move mirrors from your country to the top
```

3. If regional mirrors are unreliable, use a US fallback (move to top):

```
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
```

4. Refresh and update:

```bash
sudo pacman -Syyu
```

Choosing a US mirror is a practical fallback when local mirrors are unreliable.

---

## Removal (uninstall)

There is no automatic uninstaller. Manual removal requires reversing the install steps. If you need help, open an issue. For a step‑by‑step visual walkthrough see:

https://youtu.be/nMnWTq2H-N0?si=yzssSL-dBHa4x0l-

---

## Support

Consider supporting the project: [![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/malik2015no)

---

## External resources

- Asahi Linux (device support) — https://asahilinux.org/fedora/#device-support
- Asahi Alarm — https://asahi-alarm.org/
- External monitor discussion — https://github.com/malik-na/omarchy-mac/discussions/73
- Discord — https://discord.gg/KNQRk7dMzy

---

## Acknowledgements

Thanks to Asahi Linux and Asahi Alarm for enabling Linux on Apple Silicon, and to DHH for creating Omarchy.

If this guide helped you, please star the repository and share feedback in issues or discussions. If you enjoy Omarchy Mac, please share your experience on Twitter/X by tagging [@tiredkebab](https://x.com/tiredkebab).

---

## Omarchy Mac Contributors

Partial contributor list:

- tayowrld — https://github.com/tayowrld
- Owen Singh (itsOwen) — https://github.com/itsOwen
- Matthias Millhoff (embeatz) — https://github.com/embeatz
- George Dobreff — https://github.com/georgedobreff
- Luke Van — https://github.com/lukevanlukevan
- Wésley Guimarães — https://github.com/wesguima
- Vince Picone — https://github.com/vpicone
- Oleh Khomei — https://github.com/varyform
- Mike Deufel — https://github.com/MDeufel13
- Gwynspring — https://github.com/Gwynspring
- DinMon — https://github.com/DinMon
- Aslkhon — https://github.com/Aslkhon
