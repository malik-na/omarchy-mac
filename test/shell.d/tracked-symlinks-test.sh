#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

require_command git

# The kernel stores a symlink target verbatim. It never expands $HOME or
# $OMARCHY_PATH, and an absolute path describes whatever the author's machine
# looked like the day they ran `ln -s`. Either way the link resolves for its
# author and dangles for everyone who checks the repo out, so every tracked
# symlink has to be relative and has to land on something inside the repo.

tracked_symlinks() {
  git -C "$ROOT" ls-files --stage | awk -F'\t' '$1 ~ /^120000 / { print $2 }'
}

symlinks=()
while IFS= read -r symlink; do
  [[ -n $symlink ]] && symlinks+=("$symlink")
done < <(tracked_symlinks)

for symlink in "${symlinks[@]}"; do
  target=$(git -C "$ROOT" cat-file -p ":$symlink")

  [[ $target != /* ]] ||
    fail "tracked symlink is relative: $symlink" "absolute target: $target"

  [[ $target != *'$'* ]] ||
    fail "tracked symlink needs no shell expansion: $symlink" "unexpandable target: $target"

  resolved=$(realpath -m --relative-to="$ROOT" "$ROOT/$(dirname "$symlink")/$target")

  [[ $resolved != ../* ]] ||
    fail "tracked symlink stays inside the repo: $symlink" "escapes to: $target"

  [[ -e $ROOT/$resolved ]] ||
    fail "tracked symlink resolves to a real path: $symlink" "dangling target: $target"
done

pass "every tracked symlink is relative and resolves inside the repo (${#symlinks[@]} checked)"
