#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

install_script="$ROOT/install.sh"
build_script="$ROOT/build-packages.sh"

[[ -x $install_script ]] || fail "the Apple Silicon installer ships and is executable"
[[ -x $build_script ]] || fail "the Apple Silicon package build script ships and is executable"
pass "the Apple Silicon install scripts ship and are executable"

# Quattro renamed the setup entry points once already, and set -e turns a call
# to a command that no longer ships into a half-finished install.
while read -r command_name; do
  [[ -n $command_name ]] || continue
  [[ -x "$ROOT/bin/$command_name" ]] ||
    fail "the installer only calls commands that ship in bin/" "missing: $command_name"
# Anchored to command position so paths and filenames the script merely names,
# like omarchy-base.packages or the omarchy-build cache directory, stay out.
done < <(grep -oE '^[[:space:]]*(sudo[[:space:]]+)?omarchy-[a-z0-9-]+' "$install_script" |
  grep -oE 'omarchy-[a-z0-9-]+' | sort -u)
pass "the installer only calls commands that ship in bin/"

grep -F 'sudo omarchy-apply-system --install-user "$USER" --first-install' "$install_script" >/dev/null ||
  fail "the installer applies system setup as root for a first install"
grep -F 'omarchy-provision-user --first-install' "$install_script" >/dev/null ||
  fail "the installer finalizes the user for a first install"
pass "the installer runs first-install system and user setup"

# useradd -m ran before omarchy-settings existed, so /etc/skel never seeded
# $HOME. Without this replay the user gets no shipped configs at all.
grep -F 'omarchy-reinstall-configs' "$install_script" >/dev/null ||
  fail "the installer seeds shipped defaults into an already-created home"
pass "the installer seeds shipped defaults into an already-created home"

# Macs boot through GRUB. Depending on limine would also make
# install/login/alt-bootloaders.sh skip the plymouth setup it guards.
for limine_package in limine limine-mkinitcpio-hook limine-snapper-sync; do
  grep -qF "  $limine_package" "$build_script" ||
    fail "the package build drops $limine_package from the Apple Silicon dependencies"
done
pass "the package build drops the limine stack from the Apple Silicon dependencies"

# The refresh runs from omarchy-reinstall-configs under set -e, so a machine
# without limine must no-op rather than abort the seeding step.
grep -F 'omarchy-cmd-missing limine' "$ROOT/bin/omarchy-refresh-limine" >/dev/null ||
  fail "refreshing limine no-ops on a machine without limine"
pass "refreshing limine no-ops on a machine without limine"

# gum arrives with the omarchy package a third of the way in, so without this
# the install looks nothing like the rest of Omarchy until its last stretch.
grep -qF 'ensure_gum' "$install_script" ||
  fail "the installer installs gum up front"
gum_call=$(grep -n '^  ensure_gum$' "$install_script" | cut -d: -f1)
set_call=$(grep -n '^  install_default_package_set$' "$install_script" | cut -d: -f1)
[[ -n $gum_call && -n $set_call ]] || fail "the installer installs gum and the package set"
(( gum_call < set_call )) || fail "gum is installed before the long package phase"
grep -qF 'gum style' "$install_script" ||
  fail "the installer speaks through gum once it is available"
pass "the installer styles its output with gum from the start"
