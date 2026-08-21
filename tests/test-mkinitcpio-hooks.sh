#!/bin/bash
# Checks the HOOKS omarchy_hooks.conf produces. The file assigns HOOKS
# outright, from a list written for x86 — whatever the machine had before is
# discarded — and on Apple Silicon a missing hook is not a degraded boot but a
# wedged one. So the Asahi hook has to be put back.

set -uo pipefail

CONF="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/etc/mkinitcpio.conf.d/omarchy_hooks.conf"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
failures=0

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

# Evaluate the drop-in the way mkinitcpio does — sourced, with HOOKS already
# set from /etc/mkinitcpio.conf — and print what it leaves behind. $1 is the
# initcpio install directory to pretend the machine has.
hooks_with() {
  (
    HOOKS=(base asahi udev autodetect modconf kms keyboard keymap block filesystems fsck)
    MODULES=()
    OMARCHY_INITCPIO_INSTALL_PATH="$1"
    OMARCHY_PCI_DEVICES_PATH="$WORK/nopci"
    # shellcheck source=/dev/null
    source "$CONF" >/dev/null 2>&1
    echo "${HOOKS[*]}"
  )
}

mkdir -p "$WORK/asahi-machine" "$WORK/x86-machine"
touch "$WORK/asahi-machine/asahi"

asahi=$(hooks_with "$WORK/asahi-machine")
x86=$(hooks_with "$WORK/x86-machine")

echo "=== an Apple Silicon machine keeps its asahi hook ==="

check "asahi is in the list" grep -q ' asahi ' <<<" $asahi "
check "it sits directly after base" grep -q '^base asahi ' <<<"$asahi"
check "exactly once" [ "$(grep -o 'asahi' <<<"$asahi" | wc -l)" = "1" ]

echo
echo "=== a machine without the hook does not get it ==="

check "no asahi where the hook is not installed" \
  bash -c "! grep -q asahi <<<'$x86'"
check "the list is otherwise the same" \
  [ "${asahi/asahi /}" = "$x86" ]

echo
echo "=== the hooks the rest of the system depends on ==="

# encrypt unlocks the root, keyboard types the passphrase, filesystems mounts
# it. Losing any of them is a machine that does not boot.
for hook in base udev encrypt filesystems keyboard block; do
  check "$hook survives" grep -q " $hook " <<<" $asahi "
done

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
