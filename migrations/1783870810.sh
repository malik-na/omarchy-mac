#!/bin/bash
# One-time redirect: move installs still tracking the GitHub mirror onto the
# canonical Codeberg source.
#
# GitHub main and Codeberg main have diverged (a few GitHub commits were lost
# while the GitHub account was offline), so a plain pull would conflict — we
# hard-reset onto Codeberg main instead. The current state is preserved on a
# backup branch and any local changes are stashed first, so nothing is silently
# discarded.

codeberg_url="https://codeberg.org/malik-na/omarchy-mac.git"
current="$(git -C "$OMARCHY_PATH" remote get-url origin 2>/dev/null || true)"

case "$current" in
  *github.com*omarchy-mac* | *github.com/basecamp/omarchy*) ;;
  *)
    echo "Origin is not a GitHub omarchy-mac remote ($current); leaving unchanged"
    exit 0
    ;;
esac

echo "Redirecting Omarchy updates from GitHub to Codeberg (was: $current)"

# Fetch Codeberg FIRST — if it is unreachable, leave origin untouched so this
# migration re-runs cleanly on the next update instead of stranding the install.
if ! git -C "$OMARCHY_PATH" fetch "$codeberg_url" main --tags; then
  echo "Could not reach Codeberg; will retry on next update." >&2
  exit 1
fi

# Preserve the pre-migration state before the hard reset. The backup branch is
# always cheap insurance; the stash + recovery note only matter if the user
# actually had uncommitted local changes.
git -C "$OMARCHY_PATH" branch -f pre-codeberg-migration HEAD 2>/dev/null || true
if [[ -n "$(git -C "$OMARCHY_PATH" status --porcelain)" ]]; then
  git -C "$OMARCHY_PATH" stash push -u -m "pre-codeberg-migration" 2>/dev/null || true
  recovery_note="$HOME/omarchy-codeberg-migration-recovery.txt"
  cat >"$recovery_note" <<EOF
Omarchy update source moved from GitHub to Codeberg.

You had local changes in $OMARCHY_PATH. They were NOT discarded:
  - your previous commit history is on branch 'pre-codeberg-migration'
  - your uncommitted changes were saved to the git stash

See what you had changed:
  git -C "$OMARCHY_PATH" diff pre-codeberg-migration

Restore your uncommitted changes (may conflict against the new Codeberg tree;
the stash is kept if it does, so nothing is lost):
  git -C "$OMARCHY_PATH" stash list
  git -C "$OMARCHY_PATH" stash pop

Delete this file once you're done.
EOF
  echo "  local changes stashed; recovery instructions written to $recovery_note"
fi

git -C "$OMARCHY_PATH" remote set-url origin "$codeberg_url"
git -C "$OMARCHY_PATH" reset --hard FETCH_HEAD # diverged histories: reset, don't merge

echo -e "\e[32mMoved to the Codeberg source.\e[0m"
echo "Previous state kept on branch 'pre-codeberg-migration'. Run 'omarchy update' once more to finish."
