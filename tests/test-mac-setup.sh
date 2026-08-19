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


# localectl is not present in a test environment, and the keymap path calls it.
# Stub it once, here, so every check below makes a decision rather than tripping
# over a missing command.
km_stub=$work/km
mkdir -p "$km_stub"
cat >"$km_stub/localectl" <<'STUB'
#!/bin/bash
case "$*" in
  *list-keymaps*) printf 'us\nuk\nde\ndvorak\n' ;;
  *) echo "     VC Keymap: de" ;;
esac
STUB
chmod +x "$km_stub/localectl"

echo
echo "=== the confirmation must not end the run ==="

# `[[ ... ]] && fail` as a function's last statement returns 1 on the path where
# the condition is false — the yes path — and set -e turns that into a silent
# exit at the call site. Answering "Y" used to quit the installer.
answers() {
  local input="$1"
  (
    set -e
    encrypt_flag=1 want_encrypt=1 username=scott hostname=pancake keymap=""
    repo=example/repo ref=some-branch
    PATH="$km_stub:$PATH"
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

# With no keymap set and a stub that would answer one, the run still starts:
# if a keymap question were asked, it would swallow the "Y" and the run would
# never reach the confirmation.
check "no keymap question swallows the answer" answers 'Y
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
echo "=== every step can be re-run by name ==="

# The state machine picks the order; --step is the manual override for a step
# that half-worked, or one that did not exist when the machine was installed.
is_known_step() {
  local candidate="$1" step
  for step in "${STEPS[@]}"; do
    [[ $step == "$candidate" ]] && return 0
  done
  return 1
}

# Every step next_step can produce has to be dispatchable by name, or the
# override cannot re-run the thing that just failed.
for produced in boot-layout encrypt omarchy done; do
  check "next_step's '$produced' can be run by name" is_known_step "$produced"
done

check "fonts is reachable by name" is_known_step fonts
check "autologin is reachable by name" is_known_step autologin
check "a typo is not a step" not is_known_step boot-later

echo
echo "=== keymaps ==="

# The console keymap is the keymap the LUKS prompt uses: omarchy_hooks.conf
# bundles vconsole.conf into the initramfs. A wrong one means the machine
# rejects a passphrase its owner is typing correctly.
known_keymap() {
  PATH="$km_stub:$PATH" valid_keymap "$1"
}

check "a known keymap is accepted" known_keymap us
check "case is ignored, as localectl does" known_keymap US
check "an unknown keymap is refused" not known_keymap nonsense
check "an empty keymap is refused" not known_keymap ""
check "the current keymap is read from localectl" \
  [ "$(PATH="$km_stub:$PATH" OMARCHY_VCONSOLE_CONF=$work/none current_keymap)" = "de" ]

# A machine whose localectl cannot list keymaps is not a machine with a bad
# keymap: refusing there would block an install over a missing lookup table.
empty_stub=$work/km-empty
mkdir -p "$empty_stub"
cat >"$empty_stub/localectl" <<'STUB'
#!/bin/bash
case "$*" in
  *list-keymaps*) : ;;
  *) echo "     VC Keymap: us" ;;
esac
STUB
chmod +x "$empty_stub/localectl"

unlistable_keymap() {
  PATH="$empty_stub:$PATH" valid_keymap "$1"
}

check "anything passes when keymaps cannot be listed" unlistable_keymap us
check "even an odd one, rather than blocking the install" unlistable_keymap whatever
check "empty is still refused" not unlistable_keymap ""

# systemd reports a machine that has never set a keymap as "(unset)" or "n/a".
# Both look like keymap names to anything that just takes the text after the
# colon, and both were then rejected as unknown -- stopping the install over a
# machine's own unset default.
unset_stub=$work/km-unset
mkdir -p "$unset_stub"
cat >"$unset_stub/localectl" <<'STUB'
#!/bin/bash
case "$*" in
  *list-keymaps*) printf 'us\nuk\nde\n' ;;
  *) echo "     VC Keymap: (unset)" ;;
esac
STUB
chmod +x "$unset_stub/localectl"

check "an unset keymap falls back to us" \
  [ "$(PATH="$unset_stub:$PATH" OMARCHY_VCONSOLE_CONF=$work/none current_keymap)" = "us" ]

printf 'KEYMAP=dvorak\n' >"$work/vconsole.conf"
check "vconsole.conf wins, since the initramfs reads that" \
  [ "$(PATH="$km_stub:$PATH" OMARCHY_VCONSOLE_CONF=$work/vconsole.conf current_keymap)" = "dvorak" ]
check "and that fallback validates" \
  bash -c 'PATH="'"$unset_stub"':$PATH"; '"$(declare -f valid_keymap keymaps_listable)"'; valid_keymap us'

echo
echo "=== a staged checkout has to be the one that was asked for ==="

# The version guard rejects a branch only after cloning it, so a refused run
# leaves a tree behind. Reusing it silently is how a corrected run got as far
# as "moving /boot onto the EFI partition" before finding no such file.
make_checkout() {
  local dir="$1" url="$2" branch="$3" with_tools="$4"
  rm -rf "$dir"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" remote add origin "$url"
  git -C "$dir" checkout -q -b "$branch"
  if [[ $with_tools == "tools" ]]; then
    mkdir -p "$dir/bin"
    touch "$dir/bin/omarchy-system-boot-to-esp" "$dir/bin/omarchy-system-btrfs-migrate"
  fi
  git -C "$dir" add -A >/dev/null 2>&1
  git -C "$dir" -c user.email=t@t -c user.name=t commit -qm x --allow-empty
}

co=$work/checkout

make_checkout "$co" https://codeberg.org/scottjones/omarchy-mac.git feat/btrfs-encrypt-only tools
check "the right repo, branch and tools is reused" \
  checkout_matches "$co" scottjones/omarchy-mac feat/btrfs-encrypt-only

check "a different branch is replaced" \
  not checkout_matches "$co" scottjones/omarchy-mac quattro
check "a different repo is replaced" \
  not checkout_matches "$co" malik-na/omarchy-mac feat/btrfs-encrypt-only

# The case that actually happened: a 3.x tree from the refused run.
make_checkout "$co" https://codeberg.org/malik-na/omarchy-mac.git main bare
check "the right branch without the tools is replaced" \
  not checkout_matches "$co" malik-na/omarchy-mac main

check "a directory that is not a checkout at all is replaced" \
  not checkout_matches "$work/nothing-here" malik-na/omarchy-mac main

echo
echo "=== autologin has to name a session that exists ==="

# Session=omarchy.desktop was copied from the ISO, where that file is
# installed. On a Mac the sessions are Hyprland's, so autologin pointed at a
# file that exists only in git -- SDDM logged in to nothing and the screen
# stayed black.
sessions=$work/sessions
mkdir -p "$sessions"

session_chosen() {
  OMARCHY_SESSIONS_DIR="$sessions" desktop_session
}

check "no sessions at all is refused rather than guessed" \
  bash -c 'OMARCHY_SESSIONS_DIR="'"$sessions"'"; '"$(declare -f desktop_session)"'; ! desktop_session'

touch "$sessions/hyprland.desktop"
check "plain hyprland is used when it is all there is" \
  [ "$(session_chosen)" = "hyprland.desktop" ]

touch "$sessions/hyprland-uwsm.desktop"
check "the uwsm session wins over plain hyprland" \
  [ "$(session_chosen)" = "hyprland-uwsm.desktop" ]

touch "$sessions/omarchy.desktop"
check "Omarchy's own session wins over both" \
  [ "$(session_chosen)" = "omarchy.desktop" ]

# SDDM scans /usr/share and /usr/local/share, and the omarchy package installs
# into the second. Checking only the first made a machine with a working
# Omarchy session look like it had none -- the log from a real one read
# "/usr/local/share/wayland-sessions/omarchy.desktop".
local_sessions=$work/local-sessions
mkdir -p "$local_sessions"
touch "$local_sessions/omarchy.desktop"

check "a session in the second directory is found" \
  bash -c 'OMARCHY_SESSIONS_DIR=""; '"$(declare -f session_dirs session_file_path desktop_session)"'
    session_dirs() { printf "%s\n" "'"$sessions"'" "'"$local_sessions"'"; }
    [[ $(desktop_session) == omarchy.desktop ]]'

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
