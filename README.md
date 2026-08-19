![IMG_5776](https://github.com/user-attachments/assets/86b2651c-4b49-4ec5-ae78-023b01e46a15)

# Omarchy Mac — Dual Boot Installation
A concise, beginner-friendly guide to install Omarchy Mac (Asahi Alarm + Omarchy) alongside macOS on Apple Silicon (M1/M2).

[![License](https://img.shields.io/gitea/license/malik-na/omarchy-mac?gitea_url=https%3A%2F%2Fcodeberg.org)](LICENSE) [![Stars](https://img.shields.io/gitea/stars/malik-na/omarchy-mac?gitea_url=https%3A%2F%2Fcodeberg.org&style=social)](https://codeberg.org/malik-na/omarchy-mac/stargazers)

---

## Quick links

- Start installer — `curl https://asahi-alarm.org/installer-bootstrap.sh | sh`
- Installing Omarchy 4 once Arch is booted — [Install Omarchy Mac](#install-omarchy-mac)
- Installing it in one command, encryption included — [The short version](#the-short-version-one-command)
- Btrfs snapshots and optional disk encryption — [docs/btrfs.md](docs/btrfs.md)
- Upgrading from 3.x to Quattro (Omarchy 4) — [docs/upgrade-to-quattro.md](docs/upgrade-to-quattro.md)
- The Omarchy manual — [manual/](manual/)
- External monitor guide — https://codeberg.org/malik-na/omarchy-mac/discussions/73
- Support — https://buymeacoffee.com/malik2015no
- Discord — https://discord.gg/KNQRk7dMzy

---

## Table of contents

- [Before you begin](#before-you-begin)
- [Quick start](#quick-start)
- [Detailed installation](#detailed-installation)
  - [Run Asahi Alarm](#run-asahi-alarm)
  - [The short version: one command](#the-short-version-one-command)
  - [Optional: btrfs snapshots and disk encryption](#optional-btrfs-snapshots-and-disk-encryption)
  - [Initial Arch setup](#initial-arch-setup)
  - [Create a regular user](#create-a-regular-user)
  - [Install Omarchy Mac](#install-omarchy-mac)
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
  Its btrfs variant works too — see the next section.

### The short version: one command

On the first boot into Arch, as root:

```bash
curl -LO https://codeberg.org/malik-na/omarchy-mac/raw/branch/main/bin/omarchy-mac-setup
bash omarchy-mac-setup --encrypt
```

(The script installs from the same place by default, so `--repo`/`--ref` are
only needed to install from a fork or a branch. If Quattro has not landed on
`main` yet, add `--ref quattro` — the script checks the version it is about to
install and refuses to give you Omarchy 3 by accident.)

It asks for a hostname, username and password up front, then carries the machine
the rest of the way on its own — moving `/boot` onto the EFI partition,
encrypting the root, installing Omarchy — rebooting between steps and resuming
itself each time on tty1. The only thing you type after that is the disk
passphrase, once, when it asks you to choose one.

Expect roughly an hour, three reboots, and two questions along the way:

- **A gum dialog offering to build packages with no known aarch64 build.** Say
  no. `obs-studio` alone compiles for about three hours and then fails an
  architecture check. It defaults to no.
- **The disk passphrase**, chosen at the console on the boot that does the
  encryption. That boot then rewrites the whole partition and prints nothing
  while it does — ten to thirty minutes on a 200 GB root, and it is not stuck.

Encrypted machines log straight into the desktop afterwards: the passphrase at
boot is the authentication, and a second password immediately after it protects
nothing the first one did not.

Other flags:

- `--no-encrypt` (or answering `n`) skips the encryption and the boot-layout
  move it needs.
- `--status` reports where a machine has got to.
- `--step <name>` re-runs one step: `boot-layout`, `encrypt`, `omarchy`,
  `fonts`, `autologin`, `done`. Useful when one of them half-worked, or on a
  machine installed before a step existed.
- `--abort` stops the guided run without undoing anything already done.

The steps it drives are documented individually below and in
[docs/btrfs.md](docs/btrfs.md); run them by hand if you would rather see each
one.

### Optional: btrfs snapshots and disk encryption

For snapper snapshots and `omarchy-system-factory-reset` support — and for
full-disk encryption, which the Asahi Alarm installer does not offer at all —
run this on the fresh install, before anything else lands on it. See
[docs/btrfs.md](docs/btrfs.md).

```bash
base=https://codeberg.org/malik-na/omarchy-mac/raw/branch/main/bin
curl -LO $base/omarchy-system-boot-to-esp
curl -LO $base/omarchy-system-btrfs-migrate

# Asahi Alarm's btrfs images keep /boot on the root filesystem, where GRUB
# cannot read it once the root is encrypted. Move it first, and reboot to
# confirm the machine still boots before encrypting anything.
bash omarchy-system-boot-to-esp

bash omarchy-system-btrfs-migrate --encrypt   # omit --encrypt to stay unencrypted
```

On an ext4 install this converts the root to btrfs. On one of Asahi Alarm's
btrfs images the filesystem is already the right shape, so `--encrypt`
encrypts it in place and adds the rest of the layout — and without `--encrypt`
there is nothing left to do.

`omarchy-system-btrfs-migrate` refuses to encrypt a root that still carries
`/boot`, and says so, rather than producing a machine that boots to a `grub
rescue>` prompt. That is what `omarchy-system-boot-to-esp` is for, and the
guided setup above does both in the right order.

The machine reboots once to do the work, then you continue below.

### Initial Arch setup

Run these commands (replace placeholders where indicated):

```bash
# Configure Wi‑Fi (if required)
nmtui

# Update packages
pacman -Syu

# Install essential packages
pacman -S --needed sudo git base-devel chromium

# Enable en_US.UTF-8 locale
nano /etc/locale.gen   # uncomment en_US.UTF-8
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
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
useradd -m -G wheel <username>
passwd <username>

# Enable wheel in sudoers
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL

# Switch to your user
su - <username>
```

Unattended installs: you may use `NOPASSWD:` for wheel, but this reduces security.

### Install Omarchy Mac

As the non‑root user (the installer refuses to run as root and uses `sudo`
where it needs to):

```bash
git clone -b quattro https://codeberg.org/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy
cat version    # 4.x — if this says 3.x you are on the wrong branch
bash install.sh
```

**Mind the branch.** `main` is still the Omarchy 3.x line until Quattro is
merged into it, and its `install.sh` installs Omarchy 3 without saying which
generation it is putting on the machine — an easy hour to lose. `-b quattro` is
what makes it 4.x, and `cat version` is how you check before committing to it.
(The guided setup above reads that file and refuses to install 3.x unasked.)

That is the whole install. It takes roughly 40 minutes on a good connection,
almost all of it building the AUR packages in the default set, and it:

- installs `yay` if you do not already have it
- builds the four Omarchy packages from this checkout, since Omarchy's own
  package repo has no Apple Silicon builds
- adds the Apple Silicon package repo, installs the default package set,
  seeds your home directory, and runs system and user setup

Notes:

- A few packages have no ARM build at all and are reported at the end rather
  than failing the install. Where building one would take hours and still fail,
  the installer says so and asks before trying; answer no unless you know it
  has gained ARM support since. `OMARCHY_TRY_UNAVAILABLE=1 bash install.sh`
  forces the attempt.
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

### The machine boots to `grub rescue>`

GRUB kept its modules and kernel on the root filesystem, and the root was
encrypted underneath it. See [docs/btrfs.md](docs/btrfs.md) -- the short
version is that `/boot` has to be the EFI partition before encrypting, which
`omarchy-system-boot-to-esp` arranges and `omarchy-system-btrfs-migrate`
refuses to proceed without.

### Rolling back after a bad update

`omarchy snapshot restore` works on Apple Silicon (it does the subvolume swap
directly, since `limine-snapper-restore` only exists on x86 Limine installs).
It offers snapper's snapshots alongside `@fresh` -- the system before Omarchy
was installed -- and `@factory`, the installed system before it was yours. It
says which one you are about to restore and what is in it before doing
anything, and keeps the displaced root as `@old-<timestamp>`.

Note `/boot` is the EFI partition and is outside every snapshot, so a rollback
across a kernel update leaves the kernel and initramfs where they are; the tool
warns when the restored root has no modules for the running kernel.

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
- External monitor discussion — https://codeberg.org/malik-na/omarchy-mac/discussions/73
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
- Marcelo Alcantara — https://github.com/maralcbr
