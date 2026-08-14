#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

upgrade_to_quattro_mac="$ROOT/bin/omarchy-upgrade-to-quattro-mac"

function_body() {
  awk -v name="$1" '$0 == name "() {" { inside = 1; next } inside && $0 == "}" { exit } inside' "$upgrade_to_quattro_mac"
}

# Quattro renamed the setup entry points, and set -e turns a call to a command
# that no longer ships into a half-finished upgrade: the checkout, the system
# symlinks, and the Hyprland config are already replaced by the time this runs.
# Scoped to the function body so the retired package names stay out of it.
setup_body=$(function_body run_quattro_setup)
[[ -n $setup_body ]] || fail "the Mac Quattro upgrade has a run_quattro_setup step"
while read -r command_name; do
  [[ -n $command_name ]] || continue
  [[ -x "$ROOT/bin/$command_name" ]] ||
    fail "Mac Quattro upgrade only calls setup commands that ship in bin/" "missing: $command_name"
done < <(grep -oE '\bomarchy-[a-z0-9-]+' <<<"$setup_body" | sort -u)
pass "Mac Quattro upgrade only calls setup commands that ship in bin/"

grep -F 'sudo omarchy-apply-system --install-user "$USER" --upgrade' "$upgrade_to_quattro_mac" >/dev/null ||
  fail "Mac Quattro upgrade applies system setup as root"
grep -F 'omarchy-provision-user --force' "$upgrade_to_quattro_mac" >/dev/null ||
  fail "Mac Quattro upgrade finalizes the user without sudo"
pass "Mac Quattro upgrade runs system setup as root and user setup as the user"

# Naming them keeps the 3.x spellings from creeping back in a later merge.
if grep -qE 'omarchy-setup-system|omarchy-finalize-user' "$upgrade_to_quattro_mac"; then
  fail "Mac Quattro upgrade does not call the retired 3.x command names"
fi
pass "Mac Quattro upgrade does not call the retired 3.x command names"
