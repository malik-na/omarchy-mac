<img width="2560" height="1600" alt="screenshot-2025-09-28_11-19-38" src="https://github.com/user-attachments/assets/dbce832d-4054-4fbb-8057-e521be4859f8" />

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
2. **Configure wifi** - Run `nmtui` for network setup (if you get an error after activating your wifi, reboot)
3. **Update system** - Run `pacman -Syu`
4. **Install essential packages** - Run `pacman -S sudo git base-devel neovim chromium`
5. **Set locale** - Run `nano /etc/locale.gen` and uncomment `en_US.UTF-8`, save and exit.
Run `locale-gen`, `nano /etc/locale.conf` and it should show `LANG=en_US.UTF-8`, if it doesn't, change it. 
Now run `locale` and then `reboot` .

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

2. **Clone and setup Omarchy**:
   ```bash
   git clone https://github.com/malik-na/omarchy-mac.git ~/.local/share/omarchy
   cd ~/.local/share/omarchy
   bash install.sh
   ```

**Note**: If mirrors break during installation, run `bash fix-mirrors.sh` then run `install.sh` again.


## Omarchy Menu

Omarchy Mac now includes the **Omarchy Mac Menu** by default, which replaces Walker with fuzzel for better aarch64 compatibility and performance. The menu system uses fuzzel as the frontend while maintaining all the original functionality.

Key improvements:
- Better performance on aarch64 systems (Apple Silicon Macs)
- Fuzzel-based frontend for improved stability
- Maintains all original omarchy menu functionality
- Automatic migration from walker-based setup


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

New updates coming soon...

### If you enjoy __Omarchy Mac__, please give it a star and share your exprience on Twitter/X by tagging me [@tiredkebab](https://x.com/tiredkebab) 

Join [Omarchy Mac Discord server](https://discord.gg/KNQRk7dMzy) for updates and support.

- If you wish to donate-  [![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/malik2015no)

## Acknowledgements

Thanks [DHH](https://github.com/dhh) for creating Omarchy.

## Contributors

- Thank you [IvanKurbakov](https://github.com/tayowrld) for making [Omarchy Mac Menu](https://github.com/tayowrld/omarchy-mac-menu)
