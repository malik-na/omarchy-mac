#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

lock_on_boot="$ROOT/bin/omarchy-mac-lock-on-boot"

[[ -x $lock_on_boot ]] || fail "the Apple Silicon boot lock ships and is executable"

# Quattro replaced hyprlock with the Quickshell lock and retires the package on
# upgrade, so a fresh install has no hyprlock: the boot lock silently did
# nothing, leaving an unencrypted machine unlocked.
if grep -qE '\bhyprlock\b' "$lock_on_boot"; then
  fail "the boot lock does not call hyprlock, which Quattro no longer installs"
fi
grep -qF 'omarchy-system-lock' "$lock_on_boot" ||
  fail "the boot lock uses the Quattro lock command"
grep -qxF 'hyprlock' "$ROOT/install/omarchy-base.packages" &&
  fail "hyprlock is not in the default package set, so nothing may depend on it"
pass "the boot lock uses the lock Quattro actually installs"

# A fresh shell answers before its lock plugin can serve, so one request is
# dropped and the machine boots unlocked.
grep -qF 'omarchy-shell lock status' "$lock_on_boot" ||
  fail "the boot lock checks whether the session actually locked"
grep -qF 'secure' "$lock_on_boot" ||
  fail "the boot lock waits for the session to report secure"
pass "the boot lock re-requests until the session reports secure"

# autostart is what runs it, so a rename there loses the lock silently.
grep -qF 'omarchy-mac-lock-on-boot' "$ROOT/default/hypr/autostart.lua" ||
  fail "the Hyprland autostart still runs the boot lock"
pass "the Hyprland autostart runs the boot lock"
