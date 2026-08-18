#!/bin/bash
# Walks omarchy-mac-setup's step machine over every combination of machine
# state, including the one that bricked a MacBook: encrypting a root while
# /boot still lives on it. Needs no root — the script is sourced and next_step
# is called directly.

set -uo pipefail

TOOL="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/omarchy-mac-setup"
pass=0
failures=0

# shellcheck source=/dev/null
source "$TOOL"
set +e # the script sets -e for its own run

# next_step <boot_separate> <encrypted> <want_encrypt> <installed>
step_is() {
  local expected="$1" actual
  shift
  actual=$(next_step "$@")
  if [[ $actual == "$expected" ]]; then
    echo "✓ [boot=$1 crypt=$2 want=$3 installed=$4] → $actual"
    ((++pass))
  else
    echo "✗ [boot=$1 crypt=$2 want=$3 installed=$4] → $actual (expected $expected)"
    ((++failures))
  fi
}

echo "=== encrypted install, from a fresh Asahi Alarm btrfs image ==="

# The order that matters: layout first, encryption second, Omarchy last.
step_is boot-layout 0 0 1 0
step_is encrypt 1 0 1 0
step_is omarchy 1 1 1 0
step_is done 1 1 1 1

echo
echo "=== unencrypted install ==="

# Without encryption the boot layout is nobody's business — an unencrypted
# root with /boot on it boots fine.
step_is omarchy 0 0 0 0
step_is omarchy 1 0 0 0
step_is done 0 0 0 1

echo
echo "=== states that must never produce an encryption step ==="

# Already encrypted: never stage it twice, whatever /boot looks like.
step_is omarchy 0 1 1 0
step_is done 1 1 1 1

# Installed wins over everything: a finished machine is finished.
step_is done 0 0 1 1
step_is done 0 1 0 1

echo
echo "=== the failure this ordering exists to prevent ==="

# /boot on the root filesystem must never reach the encrypt step, because GRUB
# would lose its modules and kernel behind the LUKS header.
for want in 0 1; do
  for installed in 0 1; do
    result=$(next_step 0 0 "$want" "$installed")
    if [[ $result == "encrypt" ]]; then
      echo "✗ encrypt reached with /boot on root (want=$want installed=$installed)"
      ((++failures))
    else
      echo "✓ no encrypt with /boot on root (want=$want installed=$installed) → $result"
      ((++pass))
    fi
  done
done

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
