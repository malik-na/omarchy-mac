#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# Static checks first: these run on any machine (and in CI on aarch64) and
# assert the repo's aarch64 surface without needing Asahi hardware. The dynamic
# checks at the bottom simulate aarch64 with stubbed commands.

# Every pacman.conf the repo ships must pin Architecture = aarch64. A config
# that omits it inherits the machine's uname, which is right on a Mac today but
# silently wrong the moment upstream x86 defaults are synced back in.
for config in "$ROOT"/default/pacman/pacman*.conf; do
  grep -qF 'Architecture = aarch64' "$config" ||
    fail "every shipped pacman config pins aarch64" "missing in: $(basename "$config")"
done
pass "every shipped pacman config pins aarch64"

# Omarchy's own package repo is x86_64 only (docs/upgrade-to-quattro.md). Any
# config that still points at it makes pacman fetch aarch64 packages from an
# x86 repo and breaks every system upgrade.
leaky=()
while read -r config; do
  [[ -n $config ]] || continue
  leaky+=("$(basename "$config")")
done < <(grep -l 'pkgs\.omarchy\.org' "$ROOT"/default/pacman/pacman*.conf 2>/dev/null || true)
(( ${#leaky[@]} == 0 )) ||
  fail "no shipped pacman config points at the x86 Omarchy package repo" \
    "still x86: ${leaky[*]}"
pass "no shipped pacman config points at the x86 Omarchy package repo"

# Same for the bundled mirrorlists: an Omarchy mirror serves x86_64 only, so a
# mirrorlist that reaches one would leave pacman querying an x86 repo for
# aarch64 packages.
leaky=()
while read -r file; do
  [[ -n $file ]] || continue
  leaky+=("$(basename "$file")")
done < <(grep -l 'omarchy\.org' "$ROOT"/default/pacman/mirrorlist* 2>/dev/null || true)
(( ${#leaky[@]} == 0 )) ||
  fail "no shipped mirrorlist points at an x86 Omarchy mirror" "still x86: ${leaky[*]}"
pass "no shipped mirrorlist points at an x86 Omarchy mirror"

# Every aarch64 pacman config anywhere in the repo — not just default/pacman/ —
# has to offer [omarchy-aarch64], or herdr falls back to a multi-hour zig build
# that aarch64 rejects (install.sh:116).
missing_arm=()
for config in "$ROOT"/config/*.conf "$ROOT"/default/pacman/*.conf; do
  [[ -f $config ]] || continue
  grep -qF 'Architecture = aarch64' "$config" || continue
  grep -qF '[omarchy-aarch64]' "$config" || missing_arm+=("${config#"$ROOT"/}")
done
(( ${#missing_arm[@]} == 0 )) ||
  fail "every aarch64 pacman config offers the Omarchy ARM repo" \
    "missing [omarchy-aarch64]: ${missing_arm[*]}"
pass "every aarch64 pacman config offers the Omarchy ARM repo"

# Paths must derive from OMARCHY_PATH (AGENTS.md); a hardcoded HOME breaks once
# the checkout is wired to /usr/share/omarchy.
if grep -qF '$HOME/.local/share/omarchy' "$ROOT/bin/omarchy-refresh-pacman-mirrorlist"; then
  fail "the mirrorlist refresh derives its source from OMARCHY_PATH, not HOME"
fi
pass "the mirrorlist refresh derives its source from OMARCHY_PATH"

# The upstream x86 upgrade rewrites /etc/pacman.d/mirrorlist to x86 mirrors and
# must refuse to run on Apple Silicon (the inverse of the guard in
# omarchy-upgrade-to-quattro-mac). It is not safe to execute here — it writes
# /etc through sudo — so assert the guard statically instead.
grep -qF 'uname -m' "$ROOT/bin/omarchy-upgrade-to-quattro" &&
  grep -qF 'aarch64' "$ROOT/bin/omarchy-upgrade-to-quattro" ||
  fail "the upstream x86 upgrade fences itself off on Apple Silicon"
pass "the upstream x86 upgrade fences itself off on Apple Silicon"

# --- Simulated aarch64 environment ------------------------------------------

# The Mac fork's safety net: omarchy-pkg-add must skip a package the Arch ARM
# repos do not serve, instead of passing it to pacman and failing the whole
# transaction. Simulate pacman -Q/-Si/-S with a stub; only the ARM package
# "exists" in the fake repos.
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin"

write_stub() {
  local name="$1"
  local body="$2"

  cat >"$stub_bin/$name" <<<"$body"
  chmod +x "$stub_bin/$name"
}

# -Q answers "installed" only after a -S has installed the package (the helper
# re-checks with -Q after installing), and only for the one package that exists.
write_stub pacman '#!/bin/bash
case "$1" in
  -Q)
    if [[ $2 == "$ARM_ONLY_PKG" ]]; then
      [[ -f $PKG_TEST_STATE ]] && exit 0
      touch "$PKG_TEST_STATE"
    fi
    exit 1
    ;;
  -Si)
    if [[ $2 == "$ARM_ONLY_PKG" ]]; then
      echo "Repository : extra"
      echo "Name        : $2"
      exit 0
    fi
    exit 1
    ;;
  -S)
    printf "pacman -S %s\n" "$*" >>"$PKG_TEST_LOG"
    ;;
  *) exit 1 ;;
esac
'

write_stub omarchy-pkg-missing '#!/bin/bash
exit 0
'

write_stub sudo '#!/bin/bash
"$@"
'

ARM_ONLY_PKG="ripgrep" \
  PKG_TEST_STATE="$test_tmp/installed" \
  PKG_TEST_LOG="$test_tmp/install.log" \
  PATH="$stub_bin:$PATH" \
  "$ROOT/bin/omarchy-pkg-add" ripgrep lib32-nvidia-utils >/dev/null 2>"$test_tmp/skip.log"

grep -qF "Skipping 'lib32-nvidia-utils'" "$test_tmp/skip.log" ||
  fail "the package helper skips packages the repos do not serve" "$(cat "$test_tmp/skip.log")"
grep -qF 'ripgrep' "$test_tmp/install.log" ||
  fail "the package helper installs the available package" "$(cat "$test_tmp/install.log")"
! grep -qF 'lib32-nvidia-utils' "$test_tmp/install.log" ||
  fail "the package helper never passes an unavailable package to pacman" "$(cat "$test_tmp/install.log")"
pass "the package helper skips x86-only packages instead of failing the install"
