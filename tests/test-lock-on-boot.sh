#!/bin/bash
# Checks when the boot lock applies. It exists for unencrypted machines, which
# have no at-rest protection; on an encrypted one the passphrase at boot was
# the authentication, and the lock only asks the same person for a second
# password. Needs no root: the commands it calls are stubbed on PATH.

set -uo pipefail

TOOL="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/omarchy-mac-lock-on-boot"
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

# The script discards the output of everything it calls, so "did it try to
# lock" has to be a side effect on disk rather than something printed.
make_stubs() {
  local devtype="$1"
  rm -rf "$WORK/bin" "$WORK/attempted"
  mkdir -p "$WORK/bin"

  printf '#!/bin/bash\necho /dev/mapper/root\n' >"$WORK/bin/findmnt"
  printf '#!/bin/bash\necho %s\n' "$devtype" >"$WORK/bin/lsblk"
  # A monitor with a resolution, so the display wait returns at once.
  printf '#!/bin/bash\necho "Monitor eDP-1 (ID 0): 3024x1964@60"\n' >"$WORK/bin/hyprctl"
  # No lock state, so the script falls through to requesting one.
  printf '#!/bin/bash\nexit 1\n' >"$WORK/bin/omarchy-shell"
  printf '#!/bin/bash\nexit 1\n' >"$WORK/bin/jq"
  printf '#!/bin/bash\ntouch "%s/attempted"\n' "$WORK" >"$WORK/bin/omarchy-system-lock"
  chmod +x "$WORK/bin"/*
}

lock_attempted() {
  local devtype="$1"
  make_stubs "$devtype"
  PATH="$WORK/bin:$PATH" timeout 10 bash "$TOOL" >/dev/null 2>&1
  [[ -e $WORK/attempted ]]
}

not() {
  ! "$@"
}

check "an encrypted root is not locked on boot" not lock_attempted crypt
check "an unencrypted root still locks" lock_attempted part

# The override matters for anyone who wants the lock anyway.
lock_attempted_forced() {
  make_stubs crypt
  OMARCHY_LOCK_ON_BOOT=1 PATH="$WORK/bin:$PATH" timeout 10 bash "$TOOL" >/dev/null 2>&1
  [[ -e $WORK/attempted ]]
}

check "OMARCHY_LOCK_ON_BOOT=1 locks an encrypted root too" lock_attempted_forced

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
