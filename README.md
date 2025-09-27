
<img width="2560" height="1600" alt="screenshot-2025-09-23_23-46-46" src="https://github.com/user-attachments/assets/9d38cd95-ff1c-4bde-8756-52a94f391a9c" />

# Omarchy-mac installation steps

_Disclaimer: This guide is intended for Apple Silicon MacBooks M1/M2 and has only been tested on the M1 variant released in 2020. It is advised that you follow the instructions in the manual very carefully lest you risk bricking the MacBook or getting stuck in a Boot Loop (I will provide a fix for that as well in the end)._

## Step 1: Install Arch minimal from Asahi Alarm

Visit [https://asahi-alarm.org/](https://asahi-alarm.org/) and run the following script in your Terminal to start Asahi Alarm Installer:

```bash
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

Once inside the Asahi Alarm Installer, please follow the on-screen instructions (very carefully). A few recommendations:

- Ideally, you should have at least `50 GB` available on your SSD that you can dedicate to the Linux partition.
- Choose `Asahi Arch Minimal` from the list of OS options the installer provides.

## Step 2: Initial Arch Linux Setup

After installation, boot into Arch Linux and perform the initial setup:

1. **Log into root** - username and password: `root`
2. **Configure wifi** - Run `nmtui` for network setup
3. **Update system** - Run `pacman -Syu`
4. **Install essential packages** - Run `pacman -S sudo git base-devel neovim chromium`

## Step 3: Create User Account

Create a new user account and configure sudo access:

1. **Create user** - `useradd -m -G wheel <username>`
2. **Set password** - `passwd <username>`
3. **Configure sudo** - `EDITOR=nano visudo`
4. **Enable wheel group** - Uncomment `%wheel ALL=(ALL:ALL) ALL`
5. **Save and exit** - Ctrl O, Enter, Ctrl X
6. **Switch to new user** - `su - <username>`

## Step 4: Install AUR Helper and Omarchy

As your new user, set up the AUR helper and install Omarchy:

1. **Install yay AUR helper**:
   ```bash
   git clone https://aur.archlinux.org/yay.git
   cd yay
   makepkg -si
   ```

2. **Create directories**:
   ```bash
   mkdir -p ~/.local/share
   cd ~/.local/share
   ```

3. **Clone and setup Omarchy**:
   ```bash
   git clone https://github.com/malik-na/omarchy-mac.git
   mv omarchy-mac omarchy
   cd omarchy
   bash install.sh
   ```

**Note**: If mirrors break during installation, run `bash fix-mirrors.sh` then run `install.sh` again.

## Mirrorlist updates

Omarchy may provide a recommended mirrorlist during install, but it will not silently overwrite an existing system mirrorlist. The installer and helper scripts follow a safe default:

- If `/etc/pacman.d/mirrorlist` does not exist, Omarchy will install the bundled default.
- If it exists, Omarchy will merge `Server = ...` entries from the bundled mirrorlist into the existing file so user-configured or distribution-specific mirrors (e.g., Arch Linux ARM) are preserved.

If you want to force a full overwrite you can either run the helper with `--force` and/or `--backup` to keep a timestamped backup, or set the environment variable `OMARCHY_FORCE_MIRROR_OVERWRITE=1` during install.

## Boot Loop Recovery

In case you end up in a Boot Loop, here's the solution:

1. **Don't panic!**
2. **Follow this guide** – [https://support.apple.com/en-us/108900](https://support.apple.com/en-us/108900)

---

## Theme switching

Run `omarchy-theme-set <theme>` to apply one of the bundled styles (for example `tokyo-night`, `catppuccin`, or `everforest`). On Apple Silicon (aarch64) installs the Walker launcher now receives the same palette automatically—the installer links the Walker theme bundle and theme switching restarts Walker so its UI refreshes without manual steps.

New updates coming soon...

(Find me on X/Twitter here - [https://x.com/tiredkebab](https://x.com/tiredkebab) )

- If you want to support me -  [![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/malik2015no)


## Acknowledgements

Thanks @dhh for creating Omarchy.
