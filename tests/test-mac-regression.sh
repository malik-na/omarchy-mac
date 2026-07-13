#!/bin/bash
# Omarchy Mac regression checks: bindings, fuzzel migration, no Walker runtime paths.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
pass() { echo "✓ $*"; }
fail() { echo "✗ $*" >&2; exit 1; }

echo "=== Omarchy Mac regression checks ==="
echo "Root: $ROOT"

# Group navigation (manual Super+Ctrl+Arrow)
if grep -q 'SUPER CTRL, LEFT' "$ROOT/default/hypr/bindings/tiling-v2.conf" &&
  grep -q 'SUPER CTRL, RIGHT' "$ROOT/default/hypr/bindings/tiling-v2.conf"; then
  pass "tiling-v2 Super+Ctrl group navigation binds present"
else
  fail "tiling-v2 missing Super+Ctrl group navigation binds"
fi

# Must not reintroduce Super+Alt overload conflict for group focus
if grep -q 'SUPER ALT, LEFT, Move grouped window focus' "$ROOT/default/hypr/bindings/tiling-v2.conf"; then
  fail "tiling-v2 still overloads Super+Alt for group focus (conflicts with moveintogroup)"
else
  pass "tiling-v2 does not overload Super+Alt for group focus"
fi

# cliamp + signal-desktop app binds
if grep -q 'cliamp' "$ROOT/config/hypr/bindings.conf"; then
  pass "cliamp Super+Shift+Alt+M binding present in defaults"
else
  fail "cliamp binding missing from config/hypr/bindings.conf"
fi

if grep -q 'signal-desktop-beta' "$ROOT/config/hypr/bindings.conf"; then
  fail "signal still references signal-desktop-beta"
elif grep -q 'signal-desktop' "$ROOT/config/hypr/bindings.conf"; then
  pass "Signal binding uses signal-desktop"
else
  fail "Signal binding missing"
fi

# Launcher is fuzzel, not walker
if grep -q 'omarchy-launch-fuzzel\|fuzzel' "$ROOT/default/hypr/bindings/utilities.conf"; then
  pass "utilities Super+Space uses fuzzel"
else
  fail "utilities Super+Space does not use fuzzel"
fi

if grep -q 'omarchy-launch-walker' "$ROOT/default/hypr/bindings/utilities.conf"; then
  fail "utilities still launches walker"
else
  pass "utilities does not launch walker"
fi

# Runtime menu helpers must not require Walker
for f in omarchy-menu omarchy-menu-input omarchy-menu-select omarchy-menu-file omarchy-menu-clipboard omarchy-menu-backgrounds; do
  if grep -q 'omarchy-launch-walker' "$ROOT/bin/$f"; then
    fail "$f still calls omarchy-launch-walker"
  fi
done
pass "menu helpers do not call omarchy-launch-walker"

# Base packages: fuzzel/cliphist, not omarchy-walker as active package
if grep -qE '^fuzzel$' "$ROOT/install/omarchy-base.packages" &&
  grep -qE '^cliphist$' "$ROOT/install/omarchy-base.packages"; then
  pass "base packages include fuzzel and cliphist"
else
  fail "base packages missing fuzzel or cliphist"
fi

if grep -qE '^omarchy-walker$' "$ROOT/install/omarchy-base.packages"; then
  fail "omarchy-walker still listed as a base package"
else
  pass "omarchy-walker not in active base package list"
fi

# Walker install path is no-op
if grep -qi 'Skipping Walker' "$ROOT/install/config/walker-elephant.sh"; then
  pass "walker-elephant install is skipped on Mac"
else
  fail "walker-elephant.sh does not skip Walker setup"
fi

# Codeberg update target
if grep -q 'codeberg.org/malik-na/omarchy-mac' "$ROOT/bin/omarchy-update-git"; then
  pass "updates point at Codeberg omarchy-mac"
else
  fail "omarchy-update-git not pinned to Codeberg"
fi

# CLI metadata
if "$ROOT/bin/omarchy" commands --check >/dev/null 2>&1; then
  pass "omarchy commands --check passed"
else
  fail "omarchy commands --check failed"
fi

echo
echo "=== All Omarchy Mac regression checks passed ==="
