#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

post_install="$ROOT/install/post-install/pacman.sh"

# post-install/pacman.sh overwrites /etc/pacman.conf with one of these variants.
# pacman refuses to parse a config whose Include is missing, so every included
# file has to be installed alongside it or the system loses pacman entirely.
missing=()
while read -r included; do
  base=${included##*/}
  grep -qF "$base" "$post_install" || missing+=("$included")
done < <(grep -h '^Include = /etc/pacman.d/' "$ROOT"/default/pacman/pacman*.conf |
  awk '{ print $3 }' | sort -u)

if (( ${#missing[@]} )); then
  fail "pacman config restore installs every mirrorlist it includes" \
    "not installed by post-install/pacman.sh:$(printf '\n  %s' "${missing[@]}")"
fi
pass "pacman config restore installs every mirrorlist it includes"

# The source has to ship too, or the copy above silently does nothing.
while read -r included; do
  base=${included##*/}
  [[ $base == "mirrorlist" ]] && continue
  [[ -f "$ROOT/default/pacman/$base" ]] ||
    fail "the included mirrorlist ships in the repo" "missing: default/pacman/$base"
done < <(grep -h '^Include = /etc/pacman.d/' "$ROOT"/default/pacman/pacman*.conf |
  awk '{ print $3 }' | sort -u)
pass "every included mirrorlist ships in the repo"
