#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

mise_work="$ROOT/install/user/mise-work.sh"

# Node ships per-architecture tarballs, so an x64-only name never matches on
# Apple Silicon even when the ISO does stage one.
grep -qF 'aarch64) NODE_TARBALL_ARCH=arm64' "$mise_work" ||
  fail "the work mise setup looks for the aarch64 Node tarball"
if grep -qF 'node-v*-linux-x64.tar.gz' "$mise_work"; then
  fail "the work mise setup does not hard-code the x64 Node tarball name"
fi
pass "the work mise setup picks the Node tarball for this architecture"

# omarchy-provision-user reports iso-chroot for any --first-install, so a script
# install looks like an ISO chroot and finds no staged tarball. Failing there
# leaves the user unfinalized with no completion marker.
if grep -qE '^\s*exit 1' "$mise_work"; then
  fail "the work mise setup never aborts user setup over a missing bundled tarball"
fi
grep -qF 'mise use -g node@latest' "$mise_work" ||
  fail "the work mise setup falls back to installing Node from the network"
pass "a missing bundled Node tarball degrades to a network install"
