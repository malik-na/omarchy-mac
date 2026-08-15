#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# run_logged sources every leaf under bash -eE, where an assignment from a
# failing command substitution aborts the leaf. Hardware probes read sysfs paths
# that simply do not exist on other machines, and the abort takes down every
# later stage with it, so each probe has to tolerate a missing file.
unguarded=()
while read -r leaf; do
  while IFS= read -r probe; do
    [[ $probe == *'|| true'* ]] && continue
    unguarded+=("${leaf#"$ROOT/"}: $probe")
  done < <(grep -oE '\$\(cat /(sys|proc)/[^)]*\)' "$leaf" 2>/dev/null || true)
done < <(find "$ROOT/install" -name '*.sh' -type f | sort)

if (( ${#unguarded[@]} )); then
  fail "install leaves tolerate a missing sysfs probe" \
    "unguarded probes:$(printf '\n  %s' "${unguarded[@]}")"
fi
pass "install leaves tolerate a missing sysfs probe"
