
![IMG_5776](https://github.com/user-attachments/assets/86b2651c-4b49-4ec5-ae78-023b01e46a15)

# Omarchy Mac installation steps (_Dual Boot_)

## Step 1: Install Arch minimal from Asahi Alarm

Visit [https://asahi-alarm.org/](https://asahi-alarm.org/) and run the following script in your Terminal to start Asahi Alarm Installer:

```bash
curl https://asahi-alarm.org/installer-bootstrap.sh | sh
```

Once inside the Asahi Alarm Installer, follow the on-screen instructions carefully. A few recommendations:

- You should have at least `50 GB` available on your SSD for the Linux partition.
- Choose `Asahi Arch Minimal` from the list of OS options the installer provides.

## Step 2: One-Command Installation (Recommended)

After installation, boot into Arch Linux and run a single command to set everything up:

1. **Log into root** - username and password: `root`
2. **Configure wifi** - Run `nmtui` for network setup (if you get an error after activating your wifi, reboot)
3. **Run the bootstrap installer**:
   ```bash
   wget -qO- https://malik-na.github.io/omarchy-mac/boot.sh | bash
   ```

The bootstrap script will automatically:
- ✅ Configure locale (en_US.UTF-8)
- ✅ Update system and install essential packages
- ✅ Create your user account with sudo access
- ✅ Install yay AUR helper
- ✅ Clone and install Omarchy Mac

Just follow the prompts to choose your username and password, then sit back and relax! ☕

**Note**: If mirrors break during installation, run `bash fix-mirrors.sh` then run the bootstrap again.

---

<details>
<summary><strong>📖 Manual Installation (Advanced)</strong></summary>

If you prefer manual control, follow these steps instead:

### Step 2: Initial Arch Linux Setup

After installation, boot into Arch Linux and perform the initial setup:

1. **Log into root** - username and password: `root`
2. **Configure wifi** - Run `nmtui` for network setup (if you get an error after activating your wifi, reboot)
3. **Update system** - Run `pacman -Syu`
4. **Install essential packages** - Run `pacman -S sudo git base-devel chromium`
5. **Set locale** - Run `nano /etc/locale.gen` and uncomment `en_US.UTF-8`, save and exit.
Run `locale-gen`, then `nano /etc/locale.conf` and verify it shows `LANG=en_US.UTF-8`. If it doesn't, change it to `LANG=en_US.UTF-8`.
Run `locale` and then `reboot`.

### Step 3: Create User Account

Create a new user account and configure sudo access:

1. **Create user** - `useradd -m -G wheel <username>`
2. **Set password** - `passwd <username>`
3. **Configure sudo** - `EDITOR=nano visudo`
4. **Enable wheel group** - Uncomment `%wheel ALL=(ALL:ALL) ALL`
   - For unattended installation, uncomment `%wheel ALL=(ALL:ALL) NOPASSWD: ALL` instead (no password prompts during install)
5. **Save and exit** - Ctrl O, Enter, Ctrl X
6. **Switch to new user** - `su - <username>`

### Step 4: Install AUR Helper and Omarchy Mac

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

</details>


### External Monitor [Guide](https://github.com/malik-na/omarchy-mac/discussions/73) ❗



### If you enjoy __Omarchy Mac__, please give it a star and share your experience on Twitter/X by tagging me [@tiredkebab](https://x.com/tiredkebab)

Join [Omarchy Mac Discord server](https://discord.gg/KNQRk7dMzy) for updates and support.

- Consider supporting: [![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/malik2015no)

## Acknowledgements
- Thanks to [Asahi Linux](https://asahilinux.org/) and [Asahi Alarm](https://asahi-alarm.org/) for making Linux possible on M1/M2 Macs
- Thanks to [DHH](https://github.com/dhh) for creating Omarchy

## Contributors

