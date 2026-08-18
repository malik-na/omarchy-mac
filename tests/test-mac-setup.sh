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
echo "=== the branch must carry the tools this script drives ==="

# malik-na/quattro is a real Omarchy 4 branch that does not carry
# omarchy-system-boot-to-esp or omarchy-system-btrfs-migrate. Cloning it and
# only finding out at `bash $SRC/bin/...` would strand the machine with an
# enabled unit that fails on every boot.
repo=example/repo
ref=some-branch
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

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

# require_tools_present exits rather than returns on refusal, so each case runs
# in a subshell.
refuses_checkout() {
  ! (require_tools_present "$1" >/dev/null 2>&1)
}

accepts_checkout() {
  (require_tools_present "$1" >/dev/null 2>&1)
}

mkdir -p "$work/bin"
check "an empty checkout is refused" \
  refuses_checkout "$work"

touch "$work/bin/omarchy-system-boot-to-esp"
check "half the tools is still refused" \
  refuses_checkout "$work"

touch "$work/bin/omarchy-system-btrfs-migrate"
check "a checkout with both tools passes" \
  accepts_checkout "$work"

echo
echo "=== the confirmation must not end the run ==="

# `[[ ... ]] && fail` as a function's last statement returns 1 on the path where
# the condition is false — the yes path — and set -e turns that into a silent
# exit at the call site. Answering "Y" used to quit the installer.
answers() {
  local input="$1"
  (
    set -e
    encrypt_flag=1 want_encrypt=1 username=scott hostname=pancake
    repo=example/repo ref=some-branch
    printf '%s' "$input" | ask_questions >/dev/null 2>&1
  )
}

not() {
  ! "$@"
}

refuses_to_start() {
  ! answers "$1"
}

check "answering Y starts the run" answers 'Y
'
check "answering y starts the run" answers 'y
'
check "pressing enter starts the run" answers '
'
check "answering n stops the run" refuses_to_start 'n
'
check "answering no stops the run" refuses_to_start 'no
'

echo
echo "=== hostnames ==="

valid() {
  valid_hostname "$1"
}

invalid() {
  ! valid_hostname "$1"
}

check "a plain name is accepted" valid scotts-mac
check "digits are accepted" valid mac2
check "a fully qualified name is accepted" valid mac.home.arpa
check "the Asahi default is accepted" valid alarm
check "63 characters is accepted" valid "$(printf 'a%.0s' {1..63})"

check "empty is refused" invalid ""
check "a leading hyphen is refused" invalid -mac
check "a trailing hyphen is refused" invalid mac-
check "spaces are refused" invalid "my mac"
check "underscores are refused" invalid my_mac
check "a lone dot is refused" invalid .
check "an empty label is refused" invalid mac..home
check "64 characters in a label is refused" invalid "$(printf 'a%.0s' {1..64})"

# /etc/hosts wants the short name alongside a qualified one, and exactly once
# when the name has no domain.
hosts_entry_for() {
  local name="$1" short=${1%%.*}
  if [[ $name == "$short" ]]; then
    echo "$name"
  else
    echo "$name $short"
  fi
}

check "a qualified name carries its short form" \
  [ "$(hosts_entry_for mac.home.arpa)" = "mac.home.arpa mac" ]
check "a short name is not repeated" \
  [ "$(hosts_entry_for mac)" = "mac" ]


echo
echo "=== the initramfs check reads the config, not a built image ==="

# The first version of this check parsed lsinitcpio output and failed a
# perfectly good initramfs -- the rebuild had run [asahi] on screen while the
# check said it had not. Ask the config the build reads instead.
conf_dir=$work/mkinitcpio.conf.d
mkdir -p "$conf_dir"
printf 'HOOKS=(base udev autodetect block filesystems fsck)\n' >"$work/mkinitcpio.conf"

hooks_seen() {
  OMARCHY_MKINITCPIO_CONF="$work/mkinitcpio.conf" \
    OMARCHY_MKINITCPIO_CONFD="$conf_dir" effective_hooks
}

asahi_seen() {
  OMARCHY_MKINITCPIO_CONF="$work/mkinitcpio.conf" \
    OMARCHY_MKINITCPIO_CONFD="$conf_dir" hooks_include_asahi
}

check "the base config's hooks are read" \
  grep -q 'base udev autodetect' <<<"$(hooks_seen)"

check "no asahi when nothing provides it" not asahi_seen

# A drop-in that assigns HOOKS wholesale, the way omarchy_hooks.conf does.
printf 'HOOKS=(base udev plymouth block encrypt filesystems fsck)\n' \
  >"$conf_dir/50-omarchy.conf"
check "a drop-in assigning HOOKS wins over the base config" \
  grep -q 'plymouth' <<<"$(hooks_seen)"
check "and takes asahi with it when it does not list it" not asahi_seen

printf 'HOOKS=(base asahi udev block filesystems)\n' >"$conf_dir/60-asahi.conf"
check "a later drop-in putting asahi back is seen" asahi_seen

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
