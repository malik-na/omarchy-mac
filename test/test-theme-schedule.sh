#!/bin/bash

# Test harness for omarchy-theme-schedule.
#
# Runs the scripts against synthetic inputs and verifies outputs. Does
# not actually swap themes (slots are set equal to current so apply
# is always a no-op). Designed to be safe to run on a live system.
#
# Usage:  bash test/test-theme-schedule.sh

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$REPO/bin"

PASSES=0
FAILS=0
CURRENT_TEST=""

start_test() { CURRENT_TEST="$1"; printf '\n== %s ==\n' "$1"; }
pass()       { printf '  ok   %s\n' "$1"; PASSES=$((PASSES + 1)); }
fail()       { printf '  FAIL %s\n        %s\n' "$1" "$2"; FAILS=$((FAILS + 1)); }
assert_eq()  { [[ "$2" == "$3" ]] && pass "$1" || fail "$1" "expected: $3, got: $2"; }
assert_re()  { [[ "$2" =~ $3 ]]   && pass "$1" || fail "$1" "expected match $3, got: $2"; }
assert_in()  { [[ "$2" == *"$3"* ]] && pass "$1" || fail "$1" "expected substring $3, got: $2"; }

# --- suncalc -----------------------------------------------------------------

start_test "suncalc"

# NYC, summer solstice 2026 — published: sunrise ~05:25 EDT, sunset ~20:31 EDT.
out=$("$BIN/omarchy-theme-schedule-suncalc" 40.7128 -74.0060 2026-06-21)
sr=$(printf '%s\n' "$out" | sed -n 1p)
ss=$(printf '%s\n' "$out" | sed -n 2p)
assert_re "NYC summer sunrise format" "$sr" '^2026-06-21T05:[0-9]{2}:[0-9]{2}-04:00$'
assert_re "NYC summer sunset format"  "$ss" '^2026-06-21T20:[0-9]{2}:[0-9]{2}-04:00$'

# NYC, winter solstice — sunrise ~07:17 EST, sunset ~16:31 EST.
out=$("$BIN/omarchy-theme-schedule-suncalc" 40.7128 -74.0060 2026-12-21)
sr=$(printf '%s\n' "$out" | sed -n 1p)
ss=$(printf '%s\n' "$out" | sed -n 2p)
assert_re "NYC winter sunrise format" "$sr" '^2026-12-21T07:[0-9]{2}:[0-9]{2}-05:00$'
assert_re "NYC winter sunset format"  "$ss" '^2026-12-21T16:[0-9]{2}:[0-9]{2}-05:00$'

# Polar: Tromsø in June -> midnight sun.
out=$("$BIN/omarchy-theme-schedule-suncalc" 69.6492 18.9553 2026-06-21)
assert_in "Tromsø midnight sun" "$out" 'PERPETUAL_DAY'

# Polar: Tromsø in December -> polar night.
out=$("$BIN/omarchy-theme-schedule-suncalc" 69.6492 18.9553 2026-12-21)
assert_in "Tromsø polar night" "$out" 'PERPETUAL_NIGHT'

# Bad input.
if "$BIN/omarchy-theme-schedule-suncalc" 2>/dev/null; then
  fail "suncalc rejects missing args" "expected non-zero exit"
else
  pass "suncalc rejects missing args"
fi

# --- location ----------------------------------------------------------------

start_test "location"

override="$HOME/.config/omarchy/theme-schedule.location"
override_existed=0
if [[ -f "$override" ]]; then override_existed=1; override_backup=$(<"$override"); fi

mkdir -p "$(dirname "$override")"
printf '12.345,-67.890\n' >"$override"
got=$("$BIN/omarchy-theme-schedule-location")
assert_eq "override file is read" "$got" "12.345,-67.890"
rm -f "$override"
if (( override_existed )); then printf '%s\n' "$override_backup" >"$override"; fi

# tz-derived fallback
got=$("$BIN/omarchy-theme-schedule-location")
assert_re "tz-derived format" "$got" '^-?[0-9]+\.[0-9]+,-?[0-9]+\.[0-9]+$'

# --- apply (idempotency, drop-in correctness, time spoof) --------------------

start_test "apply"

# Save slots so we can restore.
slot_dir="$HOME/.config/omarchy/current"
saved_day=""
saved_night=""
[[ -f "$slot_dir/theme.day"   ]] && saved_day=$(<"$slot_dir/theme.day")
[[ -f "$slot_dir/theme.night" ]] && saved_night=$(<"$slot_dir/theme.night")

# Force slots equal to current theme so apply never tries to swap.
current_theme=$(<"$slot_dir/theme.name")
printf '%s\n' "$current_theme" >"$slot_dir/theme.day"
printf '%s\n' "$current_theme" >"$slot_dir/theme.night"

cleanup_slots() {
  if [[ -n "$saved_day"   ]]; then printf '%s\n' "$saved_day"   >"$slot_dir/theme.day";   else rm -f "$slot_dir/theme.day";   fi
  if [[ -n "$saved_night" ]]; then printf '%s\n' "$saved_night" >"$slot_dir/theme.night"; else rm -f "$slot_dir/theme.night"; fi
  if [[ -n "${OMARCHY_THEME_SCHEDULE_NOW:-}" ]]; then "$BIN/omarchy-theme-schedule-apply" >/dev/null 2>&1 || true; fi
}
trap cleanup_slots EXIT

# Plain apply with real time.
"$BIN/omarchy-theme-schedule-apply" >/dev/null 2>&1
ec=$?
assert_eq "apply exits 0 when slots match current" "$ec" 0

dropin="$HOME/.config/systemd/user/omarchy-theme-schedule.timer.d/calendar.conf"
[[ -f "$dropin" ]] && pass "drop-in exists" || fail "drop-in exists" "missing: $dropin"

# Check drop-in content references today's date (real now).
today=$(date +%Y-%m-%d)
content=$(<"$dropin")
assert_in "drop-in references today" "$content" "$today"

# Idempotency: second run with same conditions should not rewrite drop-in.
ts_before=$(stat -c %Y "$dropin")
sleep 1
"$BIN/omarchy-theme-schedule-apply" >/dev/null 2>&1
ts_after=$(stat -c %Y "$dropin")
assert_eq "second apply leaves drop-in untouched" "$ts_before" "$ts_after"

# Time spoof: simulate winter — drop-in should reference the spoofed date.
OMARCHY_THEME_SCHEDULE_NOW="2026-12-15T10:00:00" "$BIN/omarchy-theme-schedule-apply" >/dev/null 2>&1
content=$(<"$dropin")
assert_in "drop-in updates for spoofed winter date" "$content" "2026-12-15"
assert_in "drop-in includes spoofed tomorrow"       "$content" "2026-12-16"

# Restore drop-in to real dates by running apply normally.
"$BIN/omarchy-theme-schedule-apply" >/dev/null 2>&1
content=$(<"$dropin")
assert_in "drop-in restored to current date" "$content" "$today"

# --- hook (record-slot logic) ------------------------------------------------

start_test "hook (record-slot)"

# record-slot only runs if timer is enabled. Skip the test gracefully otherwise.
if systemctl --user is-enabled --quiet omarchy-theme-schedule.timer 2>/dev/null; then
  # Save the slot we're about to mutate (phase determined by now).
  loc=$("$BIN/omarchy-theme-schedule-location")
  lat="${loc%,*}"; lon="${loc#*,}"
  today=$(date +%Y-%m-%d)
  mapfile -t st < <("$BIN/omarchy-theme-schedule-suncalc" "$lat" "$lon" "$today")
  now=$(date +%s)
  sr=$(date -d "${st[0]}" +%s)
  ss=$(date -d "${st[1]}" +%s)
  if (( now >= sr && now < ss )); then phase=day; else phase=night; fi

  slot="$slot_dir/theme.$phase"
  before=$(<"$slot")

  "$BIN/omarchy-theme-schedule-record-slot" 'test-marker' >/dev/null 2>&1
  got=$(<"$slot")
  assert_eq "hook writes phase slot" "$got" "test-marker"

  printf '%s\n' "$before" >"$slot"

  # TICK env var should suppress the slot write.
  OMARCHY_THEME_SCHEDULE_TICK=1 "$BIN/omarchy-theme-schedule-record-slot" 'should-not-write' >/dev/null 2>&1
  got=$(<"$slot")
  assert_eq "TICK=1 suppresses slot write" "$got" "$before"
else
  printf '  skip schedule timer not enabled — record-slot exits without writing\n'
fi

# --- status output sanity ----------------------------------------------------

start_test "status"

out=$("$BIN/omarchy-theme-schedule-status" 2>&1)
assert_in "status has Day field"      "$out" "Day:"
assert_in "status has Night field"    "$out" "Night:"
assert_in "status has Location field" "$out" "Location:"
assert_in "status has Sunrise field"  "$out" "Sunrise:"

# --- summary -----------------------------------------------------------------

printf '\n----\n%d passed, %d failed\n' "$PASSES" "$FAILS"
exit $(( FAILS > 0 ))
