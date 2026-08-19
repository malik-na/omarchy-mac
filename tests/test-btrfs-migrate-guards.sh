#!/bin/bash
# Checks omarchy-system-btrfs-migrate's refusals — the cases where it must not
# touch the disk at all. Needs no root and no block devices: the script is
# sourced and its guard functions are called directly.

set -uo pipefail

MIGRATE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/omarchy-system-btrfs-migrate"
pass=0
failures=0

# shellcheck source=/dev/null
source "$MIGRATE"
set +e # the script sets -e for its own run; the checks below expect failures

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

# require_separate_boot exits on refusal, so each case runs in a subshell.
boot_check() {
  local boot_source="$1" rootdev="$2"
  (OMARCHY_BOOT_SOURCE="$boot_source" require_separate_boot "$rootdev" >/dev/null 2>&1)
}

echo "=== /boot must not live on the filesystem being encrypted ==="

# The layout that bricked an M2 MacBook Pro: Asahi Alarm keeps grub's modules,
# kernel and initramfs under /boot on the root filesystem, with the ESP holding
# only the EFI stub. Encrypting root hides grub's own prefix from it.
refuses() {
  ! boot_check "$@"
}

check "refuses when /boot is on the root device" \
  refuses /dev/nvme0n1p4 /dev/nvme0n1p4

check "refuses when /boot is not a mount point at all" \
  refuses "" /dev/nvme0n1p4

check "allows a separately mounted ESP" \
  boot_check /dev/sda1 /dev/mapper/root

check "allows an ESP on the same disk but a different partition" \
  boot_check /dev/nvme0n1p3 /dev/nvme0n1p4

echo
echo "=== @fresh is taken after the boot config is written ==="

# The baseline was snapshotted before patch_boot_config wrote cryptdevice= into
# /etc/default/grub, so restoring it and regenerating grub produced a machine
# that could not unlock itself: "device UUID=... not found", emergency shell.
# A baseline that will not boot is not a baseline.
order_is_right() {
  local func="$1" body patch_line snap_line
  body=$(sed -n "/^$func() {/,/^}/p" "$MIGRATE")
  patch_line=$(grep -n 'patch_boot_config' <<<"$body" | head -1 | cut -d: -f1)
  snap_line=$(grep -n 'snapshot_fresh' <<<"$body" | head -1 | cut -d: -f1)
  [[ -n $patch_line && -n $snap_line ]] || return 1
  (( snap_line > patch_line ))
}

check "the convert path patches boot config before snapshotting" \
  order_is_right worker_convert
check "the encrypt path does too" \
  order_is_right worker_encrypt
check "nothing else takes the snapshot" \
  [ "$(grep -c 'btrfs subvolume snapshot -r' "$MIGRATE")" = "1" ]

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
