#!/usr/bin/env bash

# Ensure target directory exists
mkdir -p "$HOME/.claude/skills"

# If OMARCHY_PATH isn't set, skip gracefully
if [ -z "${OMARCHY_PATH:-}" ]; then
  echo "OMARCHY_PATH is not set; skipping omarchy ai skill link." >&2
  exit 0
fi

src="$OMARCHY_PATH/default/omarchy-skill"
dst="$HOME/.claude/skills/omarchy"

if [ ! -e "$src" ]; then
  echo "Source skill not found at: $src (skipping)" >&2
  exit 0
fi

# Create or replace symlink. -sfn: symbolic, force, don't follow destination if it's
# a symlink to a directory (works on GNU coreutils ln). This prevents the error
# observed when the destination already exists and points to a directory.
ln -sfn "$src" "$dst" && echo "Linked $dst -> $src"
