#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

base_packages="$ROOT/install/omarchy-base.packages"
unavailable="$ROOT/install/omarchy-aarch64-unavailable.packages"

mapfile -t unavailable_packages < <(grep -vE '^[[:space:]]*(#|$)' "$unavailable")
(( ${#unavailable_packages[@]} )) || fail "the aarch64 unavailable list names at least one package"

# An entry for a package the set never installs is dead weight that reads like
# coverage, so keep the list answerable against the set it filters.
for package in "${unavailable_packages[@]}"; do
  grep -qxF "$package" "$base_packages" ||
    fail "every unavailable entry is in the default package set" "not in the set: $package"
done
pass "every unavailable entry is in the default package set"

grep -qF 'package_is_unavailable_here' "$ROOT/install.sh" ||
  fail "the installer filters the default set through the unavailable list"
pass "the installer filters the default set through the unavailable list"

# The list is a default, not a verdict: AUR packages gain ARM support over time,
# so a stale entry has to cost a prompt rather than be permanently wrong.
grep -qF 'OMARCHY_TRY_UNAVAILABLE' "$ROOT/install.sh" ||
  fail "the unavailable list can be overridden"
grep -qF '[[ -r /dev/tty ]] || return 1' "$ROOT/install.sh" ||
  fail "the installer skips without a terminal instead of blocking on a prompt"
pass "the unavailable list is a prompt-able default, and never blocks a headless install"

# These have aarch64 builds in the Omarchy ARM repo, so skipping them would
# trade a slow install for a broken one.
for package in herdr omacalc omacut omawrite; do
  for entry in "${unavailable_packages[@]}"; do
    [[ $entry == "$package" ]] &&
      fail "packages the ARM repo provides are installed, not skipped" "wrongly skipped: $package"
  done
done
pass "packages the ARM repo provides are installed, not skipped"

# Without a repo carrying them, herdr pulls zig0.15 and builds it for hours
# before aarch64 rejects it.
for config in "$ROOT"/default/pacman/pacman*.conf; do
  grep -qF '[omarchy-aarch64]' "$config" ||
    fail "every shipped pacman config offers the Omarchy ARM repo" "missing in: $(basename "$config")"
  # A Server line needs no mirrorlist installed alongside it, unlike an Include.
  grep -A3 -F '[omarchy-aarch64]' "$config" | grep -qE '^Server[[:space:]]*=' ||
    fail "the ARM repo is reached by Server, not an Include" "in: $(basename "$config")"
done
pass "every shipped pacman config offers the Omarchy ARM repo"

# The shipped config only reaches /etc during post-install, which runs after the
# package set. Adding the repo any later leaves herdr building zig from source
# for two hours, so the order in main() is the whole point of the fix.
repo_call=$(grep -n '^  ensure_arm_package_repo$' "$ROOT/install.sh" | cut -d: -f1)
set_call=$(grep -n '^  install_default_package_set$' "$ROOT/install.sh" | cut -d: -f1)
[[ -n $repo_call && -n $set_call ]] || fail "the installer adds the ARM repo and installs the set"
(( repo_call < set_call )) ||
  fail "the ARM repo is added before the default package set is installed"
pass "the ARM repo is added before the default package set is installed"
