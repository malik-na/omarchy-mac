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
  - [First boot: connect to the network](#first-boot-connect-to-the-network)
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

Choose `Asahi Alarm Minimal (BTRFS)`. When the installer finishes and you boot
into Arch, connect to Wi‑Fi with `nmtui` first, then continue with the detailed
instructions below.

---

## Detailed installation

Follow these steps after the installer has finished and you have booted into the new Arch system.

### Run Asahi Alarm

- From macOS Terminal run the quick start command above.
- In the installer choose `Asahi Alarm Minimal (BTRFS)` and allocate at least
  50 GB for Linux. The plain `Asahi Alarm Minimal` (ext4) works too — the setup
  below converts it — but the BTRFS image already has the right shape.

### First boot: connect to the network

Boot into Arch, log in as root, and get online before anything else — every
path below starts with a download:

```bash
nmtui
```

If `nmtui` shows an error right after activating the connection, reboot and try
again.

### The short version: one command

On the first boot into Arch, as root and with the network up:

```bash
curl -fsSL https://codeberg.org/malik-na/omarchy-mac/raw/branch/quattro/bin/omarchy-mac-setup | bash
```

`quattro` is the repository's default branch and the script installs from it by
default. It also checks the version it is about to install and stops rather
than giving you Omarchy 3 by accident.

There is nothing to prepare beyond the network: no pacman update, no locale
setup, no user creation. The script installs what it needs, creates your user
and sets up sudo itself, and Omarchy's shell environment falls back to a UTF‑8
locale on its own. The manual steps further down are the by‑hand alternative,
not prerequisites.

You are root at this point, so no `sudo` — and on a minimal image `sudo` is not
installed yet anyway. To read the script before running it, or to pass more
options:

```bash
curl -LO https://codeberg.org/malik-na/omarchy-mac/raw/branch/quattro/bin/omarchy-mac-setup
bash omarchy-mac-setup --no-encrypt
```

(`--repo <owner/repo>` installs from a fork the same way.)

It asks whether to encrypt (yes by default), then for a hostname, username and
password, then carries the machine
the rest of the way on its own — moving `/boot` onto the EFI partition,
encrypting the root, installing Omarchy — rebooting between steps and resuming
itself each time on tty1. The only thing you type after that is the disk
passphrase, once, when it asks you to choose one.

Expect about fifteen minutes, three reboots, and two questions along the way.
(Measured on an M2 Max: fourteen minutes from the first boot into Asahi Alarm to
the Omarchy desktop, after roughly ten minutes for the Asahi Alarm installer
itself. Almost nothing is compiled locally -- the aarch64 package repo carries
the default set.)

- **A gum dialog offering to build packages with no known aarch64 build.** Say
  no. `obs-studio` alone compiles for about three hours and then fails an
  architecture check. It defaults to no.
- **The disk passphrase**, chosen at the console on the boot that does the
  encryption. That boot then rewrites every block of the partition, printing
  cryptsetup's own progress every five seconds — percentage, bytes written,
  throughput and an ETA — so you can watch it rather than wonder. On an M2 Max
  that runs at about 1 GiB/s, so a 200 GB root takes roughly three and a half
  minutes. It is safe to interrupt: the next boot resumes where it stopped.

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
- `--keep-root-password` leaves root's password as Asahi Alarm shipped it.
  By default it is locked once your user exists with a password and sudo: the
  shipped root password is well known, and nothing needs it afterwards. Recovery
  is unaffected — sudo, the initramfs shell, and `init=/bin/bash` all still work.

The steps it drives are documented individually below and in
[docs/btrfs.md](docs/btrfs.md); run them by hand if you would rather see each
one.

### Optional: btrfs snapshots and disk encryption

For snapper snapshots and `omarchy-system-factory-reset` support — and for
full-disk encryption, which the Asahi Alarm installer does not offer at all —
run this on the fresh install, before anything else lands on it. See
[docs/btrfs.md](docs/btrfs.md).

```bash
base=https://codeberg.org/malik-na/omarchy-mac/raw/branch/quattro/bin
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

**Skip this and the next two sections if you ran the one command above** — it
does all of this itself. What follows is the manual path.

As root, with the network already up:

```bash
# Update packages
pacman -Syu

# Install what the manual install needs
pacman -S --needed sudo git base-devel

# Set the system locale (the minimal image ships without one)
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

The locale step is belt and braces rather than a requirement — Omarchy's shell
environment falls back to a UTF‑8 locale when the system sets none.

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
git clone https://codeberg.org/malik-na/omarchy-mac.git ~/.local/share/omarchy
cd ~/.local/share/omarchy
cat version    # 4.x — if this says 3.x you are on the wrong branch
bash install.sh
```

**Mind the branch.** A plain clone gets `quattro`, the default branch and the
Omarchy 4 line. `main` still carries Omarchy 3.x, and its `install.sh` installs
Omarchy 3 without saying which generation it is putting on the machine — an
easy hour to lose. `cat version` is how you check before committing to it.
(The guided setup above reads that file and refuses to install 3.x unasked.)

That is the whole install. It takes under ten minutes on a good connection --
most of the default set now comes prebuilt from the aarch64 package repo rather
than being compiled here -- and it:

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

### SSH stopped working after the install

Asahi Alarm ships openssh enabled — the images are built for headless boards —
and Omarchy's install turns on a default-deny firewall that never opens port 22.
Nothing is uninstalled; the machine simply stops answering, which looks exactly
like sshd having been removed. This bites on Apple Silicon in particular,
because the install is often driven from another machine.

Turn it back on deliberately:

```bash
omarchy-setup-security-sshd
```

It enables `sshd`, adds `ufw limit 22/tcp`, and offers to fetch your public keys
from `https://github.com/<user>.keys`. The same thing lives in the menu under
Setup → Security → SSH.

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
