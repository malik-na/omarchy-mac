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
echo "=== the encryption pass has to be visible ==="

# cryptsetup's --batch-mode suppresses reencryption progress along with
# confirmations, so --progress-frequency printed nothing and an encryption pass
# looked exactly like a hung machine for ten to thirty minutes. The passphrase
# goes in a keyfile now, which is what frees stdin to answer the confirmation
# that -q was there to avoid.
reencrypt_calls=$(grep -n 'cryptsetup reencrypt' "$MIGRATE")

check "cryptsetup reencrypt is called" \
  [ -n "$reencrypt_calls" ]
check "no reencrypt call silences itself with --batch-mode" \
  bash -c "! grep -A3 'cryptsetup reencrypt' '$MIGRATE' | grep -q -- '--batch-mode'"
check "progress is asked for" \
  bash -c "grep -A3 'cryptsetup reencrypt' '$MIGRATE' | grep -q -- '--progress-frequency'"
check "its interval can be turned down to watch it work" \
  grep -q 'OMARCHY_BTRFS_PROGRESS_FREQUENCY' "$MIGRATE"
check "the passphrase goes to a keyfile, not stdin" \
  bash -c "grep -A3 'cryptsetup reencrypt' '$MIGRATE' | grep -q -- '--key-file=\"\$keyfile\"'"
check "the keyfile lives on tmpfs and is removed" \
  bash -c "grep -q 'keyfile=/run/omb-key' '$MIGRATE' && grep -q 'rm -f \"\$keyfile\"' '$MIGRATE'"
check "it needs no applet the initramfs might lack" \
  bash -c "! sed -n '/^reencrypt_with_progress/,/^}/p' '$MIGRATE' | grep -v '^\s*#' | grep -qE 'mktemp|chmod'"
check "a confirmation cannot block the boot" \
  grep -qF "printf 'YES" "$MIGRATE"

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
