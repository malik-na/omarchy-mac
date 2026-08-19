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
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
