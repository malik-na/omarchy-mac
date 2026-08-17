# Btrfs on Omarchy Mac

The x86 Omarchy Quattro ISO installs onto btrfs and gets snapshots, snapper
retention, and `omarchy-system-factory-reset` for free. Asahi Alarm installs
land on ext4, where none of that works. `omarchy-system-btrfs-migrate` closes
that gap: run it on a fresh Asahi Arch Minimal install and it rebuilds the
root partition as btrfs — optionally inside a LUKS2 container — with the same
subvolume layout the ISO creates.

## When to run it

Immediately after the Asahi Alarm installer, on the first boot into Arch,
**before** `bootstrap.sh`. The conversion stages the whole system through RAM,
which is only safe while the install is small and disposable. It refuses to
run when the used space does not comfortably fit in memory.

## Usage

As root on the fresh install:

```bash
curl -LO https://codeberg.org/malik-na/omarchy-mac/raw/branch/main/bin/omarchy-system-btrfs-migrate
bash omarchy-system-btrfs-migrate --encrypt   # omit --encrypt to stay unencrypted
```

Confirm with `convert`, reboot, and the conversion runs early in boot, before
the root is mounted:

1. The system is copied into RAM (a fresh install is a few GB).
2. With `--encrypt`, a LUKS2 container is created — you choose the disk
   passphrase on the console at this point. Every later boot asks for it.
3. The partition is reformatted as btrfs with subvolumes `@` (root), `@home`,
   and `@log`, and the system is restored into `@`.
4. A read-only snapshot `@fresh` of the just-converted system is taken.
5. Boot continues straight into the converted root; a one-shot service on
   that boot regenerates the GRUB config and initramfs, then removes itself.

Then proceed with the normal Omarchy install (`bootstrap.sh`). When
`install.sh` finishes on a btrfs root it snapshots the installed system as
`@factory`, and the snapper config that upstream ships activates instead of
being skipped.

## What you get

- **snapper** — pacman transactions get pre/post snapshots with Omarchy's
  retention config; `sudo snapper -c root list` to see them.
- **`sudo omarchy-system-factory-reset`** — returns the machine to the
  fully-installed, no-user state captured in `@factory`.
- **`@fresh`** — the pre-Omarchy baseline. Rolling back to it and re-running
  the installer is the fast way to test install changes end to end (below).

## Rolling back to the pre-Omarchy state

`@fresh` is the fresh Asahi Alarm system from just after the conversion. To
rewind the whole install (this discards `/`, keeps `@home` and `@log`):

```bash
sudo mkdir -p /mnt/top
sudo mount -o subvolid=5 "$(findmnt -no SOURCE / | sed 's/\[.*\]//')" /mnt/top
sudo btrfs subvolume snapshot /mnt/top/@fresh /mnt/top/@new   # writable clone
sudo mv /mnt/top/@ /mnt/top/@old-$(date +%s)
sudo mv /mnt/top/@new /mnt/top/@
sudo reboot
```

After verifying the reboot, delete the parked `@old-*` subvolume from
`/mnt/top`. Note `@home` survives the rollback — delete and recreate it too if
you want the full fresh state.

## Limitations

- `/boot` lives on the (vfat, unencrypted) ESP. Snapshots and rollbacks never
  cover the kernel, initramfs, or GRUB config. After rolling `@` back across a
  kernel update, run `mkinitcpio -P` if modules and kernel disagree.
- The RAM staging makes this a fresh-install tool, not a general ext4→btrfs
  migrator for a system with data on it.
- On encrypted installs, `omarchy-system-factory-reset`'s provisioning-window
  auto-unlock injects its kernel argument via Limine's entry tool, which does
  not exist on the Mac's GRUB boot chain. The reset still works; the first
  boot after it asks for the disk passphrase instead of unlocking itself.

## Testing changes to the migration

`tests/test-btrfs-migrate-rehearsal.sh` (as root) exercises the conversion
core — staging, LUKS, subvolume layout, restore fidelity, fstab generation —
against a loop device without touching the machine's disks.
