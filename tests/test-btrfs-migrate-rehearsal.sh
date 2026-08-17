#!/bin/bash
# Rehearses omarchy-system-btrfs-migrate's conversion core on a loop device:
# stages a fake ext4 root, converts it (plain and LUKS-encrypted), and checks
# the subvolume layout, restore fidelity, and generated fstab.
#
# Needs root (loop devices, mounts, mkfs) and btrfs-progs + cryptsetup.
# The machine's own disks are never touched.

set -euo pipefail

MIGRATE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/omarchy-system-btrfs-migrate"
WORK=$(mktemp -d /tmp/omarchy-btrfs-rehearsal.XXXXXX)
LOOP=""
MNT="$WORK/mnt"
pass=0
failures=0

if (( EUID != 0 )); then
  echo "SKIP: this rehearsal needs root (loop devices and mounts)"
  exit 0
fi
command -v mkfs.btrfs >/dev/null || { echo "SKIP: btrfs-progs not installed"; exit 0; }

cleanup() {
  umount -R "$MNT" 2>/dev/null || true
  # Work mounts a failed migrate run may have left behind
  local m
  for m in /run/omb-src /run/omb-new /run/omb-ram /run/omb-esp /run/omb-final; do
    umount "$m" 2>/dev/null || true
  done
  cryptsetup close omb-rehearse 2>/dev/null || true
  [[ -n $LOOP ]] && losetup -d "$LOOP" 2>/dev/null || true
  rm -rf "$WORK"
}
trap cleanup EXIT

# Clear leftovers from a previous failed run before starting
cleanup 2>/dev/null || true
mkdir -p "$WORK"

check() {
  local label="$1"
  shift
  if "$@"; then
    echo "✓ $label"
    ((++pass))
  else
    echo "✗ $label"
    ((++failures))
  fi
}

make_fake_root() {
  local img="$WORK/root.img" root="$WORK/seed"
  rm -f "$img"
  truncate -s 1G "$img"
  LOOP=$(losetup --find --show "$img")
  mkfs.ext4 -q "$LOOP"

  rm -rf "$root"
  mkdir -p "$root"
  mount "$LOOP" "$root"

  mkdir -p "$root"/{etc,home/tester,var/log,usr/bin,boot}
  cat >"$root/etc/fstab" <<EOF
UUID=$(blkid -o value -s UUID "$LOOP") / ext4 rw,relatime 0 1
UUID=ABCD-1234 /boot vfat rw,relatime 0 2
EOF
  echo "hello from home" >"$root/home/tester/file.txt"
  echo "a log line" >"$root/var/log/test.log"
  echo "#!/bin/true" >"$root/usr/bin/tool"
  chmod 755 "$root/usr/bin/tool"
  chown 1000:1000 "$root/home/tester" "$root/home/tester/file.txt"
  setfattr -n user.omarchy -v rehearsal "$root/usr/bin/tool"
  ln "$root/usr/bin/tool" "$root/usr/bin/tool-hardlink"
  ln -s tool "$root/usr/bin/tool-symlink"
  truncate -s 64M "$root/var/sparse.img"

  umount "$root"
}

verify_conversion() {
  local encrypted="$1" dev="$LOOP"

  if [[ $encrypted == 1 ]]; then
    check "loop device is LUKS" [ "$(blkid -o value -s TYPE "$LOOP")" = crypto_LUKS ]
    printf '%s' "$OMARCHY_BTRFS_PASSPHRASE" |
      cryptsetup open --key-file=- "$LOOP" omb-rehearse
    dev=/dev/mapper/omb-rehearse
  fi

  check "device carries btrfs" [ "$(blkid -o value -s TYPE "$dev")" = btrfs ]

  mkdir -p "$MNT"
  mount -o subvolid=5 "$dev" "$MNT"

  local subvols
  subvols=$(btrfs subvolume list "$MNT" | awk '{print $NF}' | sort | tr '\n' ' ')
  check "subvolume layout is @ @fresh @home @log" [ "$subvols" = "@ @fresh @home @log " ]
  local fresh_ro
  fresh_ro=$(btrfs property get -ts "$MNT/@fresh" ro)
  check "@fresh is read-only" [ "$fresh_ro" = "ro=true" ]

  check "home content landed in @home" \
    grep -q "hello from home" "$MNT/@home/tester/file.txt"
  check "home ownership preserved" \
    [ "$(stat -c %u:%g "$MNT/@home/tester/file.txt")" = "1000:1000" ]
  check "log content landed in @log" [ -f "$MNT/@log/test.log" ]
  check "/home in @ is an empty mount point" \
    [ -z "$(ls -A "$MNT/@/home")" ]
  local xattr_val
  xattr_val=$(getfattr --only-values -n user.omarchy "$MNT/@/usr/bin/tool" 2>/dev/null || true)
  check "xattr preserved" [ "$xattr_val" = "rehearsal" ]
  check "hardlink preserved" \
    [ "$(stat -c %i "$MNT/@/usr/bin/tool")" = "$(stat -c %i "$MNT/@/usr/bin/tool-hardlink")" ]
  check "symlink preserved" [ -L "$MNT/@/usr/bin/tool-symlink" ]

  local fs_uuid
  fs_uuid=$(blkid -o value -s UUID "$dev")
  check "fstab mounts @ by the new UUID" \
    grep -q "UUID=$fs_uuid / btrfs .*subvol=@ " "$MNT/@/etc/fstab"
  check "fstab mounts @home" grep -q "subvol=@home" "$MNT/@/etc/fstab"
  check "fstab mounts @log at /var/log" grep -q "/var/log btrfs .*subvol=@log" "$MNT/@/etc/fstab"
  check "fstab keeps the ESP line" grep -q "UUID=ABCD-1234 /boot vfat" "$MNT/@/etc/fstab"
  check "fstab has no ext4 root left" \
    bash -c "! grep -q ' / ext4 ' '$MNT/@/etc/fstab'"

  umount "$MNT"
  if [[ $encrypted == 1 ]]; then
    cryptsetup close omb-rehearse
  fi
}

echo "=== Rehearsal 1: plain btrfs conversion ==="
make_fake_root
"$MIGRATE" --rehearse "$LOOP"
verify_conversion 0
losetup -d "$LOOP"
LOOP=""

echo
echo "=== Rehearsal 2: LUKS2 + btrfs conversion ==="
if command -v cryptsetup >/dev/null; then
  export OMARCHY_BTRFS_PASSPHRASE="rehearsal-passphrase"
  make_fake_root
  "$MIGRATE" --rehearse "$LOOP" --encrypt
  verify_conversion 1
else
  echo "SKIP: cryptsetup not installed"
fi

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
