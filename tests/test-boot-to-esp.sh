#!/bin/bash
# Checks the parts of omarchy-system-boot-to-esp that can go wrong silently:
# the fstab rewrite and the ESP capacity check. Needs no root — the script is
# sourced and its functions are called directly.

set -uo pipefail

TOOL="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/omarchy-system-boot-to-esp"
pass=0
failures=0

# shellcheck source=/dev/null
source "$TOOL"
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

not() {
  ! "$@"
}

# An fstab of the shape Asahi Alarm's btrfs image writes.
FSTAB='# Static information about the filesystems.
# <file system> <dir> <type> <options> <dump> <pass>
UUID=725346d2-f127-47bc-b464-9dd46155e8d6 / btrfs rw,noatime,subvol=@ 0 0
UUID=725346d2-f127-47bc-b464-9dd46155e8d6 /home btrfs rw,noatime,subvol=@home 0 0
UUID=C526-8700 /boot/efi vfat rw,relatime,fmask=0022 0 2'

rewritten=$(printf '%s\n' "$FSTAB" | rewrite_esp_mountpoint)
commented=$(printf '#UUID=C526-8700 /boot/efi vfat defaults 0 2\n' | rewrite_esp_mountpoint)

echo "=== fstab rewrite ==="

check "the ESP keeps its UUID and options, mounted at /boot" \
  grep -q '^UUID=C526-8700 /boot vfat rw,relatime,fmask=0022 0 2$' <<<"$rewritten"

check "nothing mounts at /boot/efi any more" \
  not grep -q '/boot/efi' <<<"$rewritten"

check "the root line is untouched" \
  grep -q '^UUID=725346d2-f127-47bc-b464-9dd46155e8d6 / btrfs rw,noatime,subvol=@ 0 0$' <<<"$rewritten"

check "the /home line is untouched" \
  grep -q '/home btrfs rw,noatime,subvol=@home' <<<"$rewritten"

check "comments survive" \
  grep -q '^# <file system> <dir> <type>' <<<"$rewritten"

check "line count is unchanged" \
  [ "$(wc -l <<<"$rewritten")" = "$(wc -l <<<"$FSTAB")" ]

check "a commented-out ESP line is not revived" \
  grep -q '^#UUID=C526-8700 /boot/efi' <<<"$commented"

echo
echo "=== ESP capacity ==="

# The real numbers from the machine this was written for: 186 MiB of /boot
# against 375 MiB free.
check "186 MiB of /boot fits in 375 MiB free" \
  boot_fits_esp $((186 * 1024)) $((375 * 1024))

check "300 MiB does not fit in 375 MiB — headroom is kept for kernel updates" \
  not boot_fits_esp $((300 * 1024)) $((375 * 1024))

check "a full ESP is refused" \
  not boot_fits_esp $((186 * 1024)) 0

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
