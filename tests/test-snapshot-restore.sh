#!/bin/bash
# Checks the parts of omarchy-mac-snapshot-restore that decide what to restore.
# The destructive half — snapshot, move, move — is not exercised here; this
# covers where snapshots are looked for and how snapper's list is read.

set -uo pipefail

TOOL="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/omarchy-mac-snapshot-restore"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
failures=0

# shellcheck source=/dev/null
source "$TOOL"
set +e

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

matches() {
  local pattern="$1" text="$2"
  grep -qE -- "$pattern" <<<"$text"
}

echo "=== where a snapper snapshot lives at the top of the tree ==="

# Snapper makes .snapshots a subvolume inside the root it snapshots, so a root
# mounted from @ puts them under @/.snapshots -- not at the top level, where
# looking for them would find nothing and report no snapshots at all.
check "snapshot 7 is @/.snapshots/7/snapshot" \
  [ "$(snapshot_subvol_path 7)" = "@/.snapshots/7/snapshot" ]
check "the number is not interpreted" \
  [ "$(snapshot_subvol_path 142)" = "@/.snapshots/142/snapshot" ]

echo
echo "=== reading snapper's list ==="

mkdir -p "$WORK/bin"
# Real snapper output has more columns than anyone remembers, and their order
# has changed between versions -- which is the point of reading the header.
cat >"$WORK/bin/snapper" <<'STUB'
#!/bin/bash
cat <<'CSV'
config,subvolume,number,default,active,date,user,used-space,cleanup,description,userdata
root,/,0,no,yes,,root,,,current,
root,/,1,no,no,2026-08-18 20:11:02,root,1.2 MiB,number,omarchy 4.0.0,
root,/,2,no,no,2026-08-18 21:44:31,root,900 KiB,number,,
CSV
STUB
chmod +x "$WORK/bin/snapper"

listed=$(PATH="$WORK/bin:$PATH" list_snapper_snapshots)

check "snapshot 0 — the live system — is not offered" \
  bash -c "! grep -q '^0	' <<<'$listed'"
check "real snapshots are listed" \
  [ "$(wc -l <<<"$listed")" = "2" ]
check "the number comes first" \
  grep -q '^1	' <<<"$listed"
check "the date is carried" \
  grep -q '2026-08-18 20:11:02' <<<"$listed"
check "the description is carried" \
  grep -q 'omarchy 4.0.0' <<<"$listed"
check "a snapshot with no description still lists" \
  grep -q '^2	' <<<"$listed"

echo
echo "=== saying what is in a snapshot before restoring it ==="

# @fresh and @factory sit next to each other on the menu and read alike. One
# has Omarchy in it and one does not, and picking the wrong one costs a reboot
# to discover -- so the difference is stated before the swap, not after.
TOP=$WORK/top
mkdir -p "$TOP/@fresh/usr/share" "$TOP/@factory/usr/share/omarchy"
printf '4.0.0\n' >"$TOP/@factory/usr/share/omarchy/version"

check "a pre-Omarchy snapshot says so" \
  [ "$(describe_subvolume @fresh)" = "no Omarchy installed in it" ]
check "an installed one names the version" \
  [ "$(describe_subvolume @factory)" = "Omarchy 4.0.0 is installed in it" ]

mkdir -p "$TOP/@odd/usr/share/omarchy"
check "a version file that is missing is not fatal" \
  [ "$(describe_subvolume @odd)" = "no Omarchy installed in it" ]

echo
echo "=== the menu says what each choice contains, before it is chosen ==="

# A mid-install snapper snapshot was restored once while @fresh was intended:
# "snapshot 1  <date>" says nothing about what is in it, and the contents line
# only appeared in the confirmation text afterwards. The label carries it now.
label_names_contents() {
  matches 'Omarchy 4.0.0 is installed in it' "$(choice_label 'snapshot 1  2026-08-20' @factory)"
}
label_names_absence() {
  matches 'no Omarchy installed in it' "$(choice_label '@fresh  before Omarchy' @fresh)"
}
label_keeps_its_summary() {
  matches 'snapshot 1' "$(choice_label 'snapshot 1  2026-08-20' @factory)"
}

check "a row naming an installed snapshot says which version" label_names_contents
check "a row for a pre-Omarchy snapshot says so" label_names_absence
check "the row keeps its own description too" label_keeps_its_summary

# gum choose lands on the first row, so the two curated, documented choices have
# to come before the machine-generated snapper list -- otherwise an accidental
# Enter picks a snapshot from the middle of an install.
baselines_offered_first() {
  local baseline_line snapper_line
  baseline_line=$(grep -n 'for baseline in @fresh @factory' "$TOOL" | cut -d: -f1)
  snapper_line=$(grep -n 'done < <(list_snapper_snapshots)' "$TOOL" | cut -d: -f1)
  (( baseline_line < snapper_line ))
}

check "@fresh and @factory are offered before the snapper snapshots" baselines_offered_first

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
