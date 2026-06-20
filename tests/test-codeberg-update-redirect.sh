#!/bin/bash
# Safe validation for Codeberg update/reinstall redirect (PR #145 / GitHub #181).
# Runs on macOS or Linux without touching an existing Omarchy install.

set -euo pipefail

OMARCHY_REPO_URL="${OMARCHY_REPO_URL:-https://codeberg.org/malik-na/omarchy-mac.git}"
GITHUB_LEGACY_URL="${GITHUB_LEGACY_URL:-https://github.com/malik-na/omarchy-mac.git}"
TEST_DIR="${TEST_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/omarchy-redirect-test.XXXXXX")}"
KEEP_TEST_DIR="${KEEP_TEST_DIR:-0}"
SOURCE_DIR="${SOURCE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

cleanup() {
  if [[ $KEEP_TEST_DIR == 1 ]]; then
    echo "ℹ Left test directory at: $TEST_DIR"
    return
  fi
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

pass() { echo "✓ $*"; }
fail() { echo "✗ $*" >&2; exit 1; }

echo "=== Codeberg update redirect validation ==="
echo "Source: $SOURCE_DIR"
echo "Temp clone: $TEST_DIR"

for script in boot.sh bin/omarchy-update-git bin/omarchy-reinstall-git; do
  if bash -n "$SOURCE_DIR/$script"; then
    pass "shell syntax: $script"
  else
    fail "shell syntax check failed: $script"
  fi
done

if git -C "$SOURCE_DIR" diff --check >/dev/null 2>&1; then
  pass "git diff --check (no conflict markers/whitespace errors)"
else
  fail "git diff --check reported issues in source tree"
fi

grep -q 'codeberg.org/malik-na/omarchy-mac.git' "$SOURCE_DIR/bin/omarchy-update-git" \
  || fail "omarchy-update-git missing Codeberg URL"
grep -q 'remote.origin.url' "$SOURCE_DIR/bin/omarchy-update-git" \
  || fail "omarchy-update-git missing origin rewrite"
grep -q 'codeberg.org/malik-na/omarchy-mac.git' "$SOURCE_DIR/bin/omarchy-reinstall-git" \
  || fail "omarchy-reinstall-git missing Codeberg clone URL"
grep -q 'github.com/basecamp/omarchy' "$SOURCE_DIR/bin/omarchy-reinstall-git" \
  && fail "omarchy-reinstall-git still references basecamp/omarchy"

pass "redirect strings present in bin scripts"

echo
echo "=== Simulate legacy GitHub install + update redirect ==="

git clone --depth 1 "$GITHUB_LEGACY_URL" "$TEST_DIR/legacy-github-clone" >/dev/null
export OMARCHY_PATH="$TEST_DIR/legacy-github-clone"

initial_origin="$(git -C "$OMARCHY_PATH" remote get-url origin)"
[[ $initial_origin == *github.com/malik-na/omarchy-mac* ]] \
  || fail "expected GitHub legacy origin, got: $initial_origin"
pass "legacy clone origin is GitHub"

# Replicate the redirect block from bin/omarchy-update-git without fetch/pull/hyprctl.
if git -C "$OMARCHY_PATH" remote get-url origin &>/dev/null; then
  git -C "$OMARCHY_PATH" config remote.origin.url "$OMARCHY_REPO_URL"
else
  git -C "$OMARCHY_PATH" remote add origin "$OMARCHY_REPO_URL"
fi

updated_origin="$(git -C "$OMARCHY_PATH" remote get-url origin)"
[[ $updated_origin == "$OMARCHY_REPO_URL" ]] \
  || fail "origin rewrite failed: $updated_origin"
pass "origin rewritten to Codeberg"

if git -C "$OMARCHY_PATH" fetch --dry-run origin >/dev/null 2>&1; then
  pass "dry-run fetch against Codeberg succeeded"
else
  fail "dry-run fetch against Codeberg failed (check network/DNS)"
fi

echo
echo "=== Reinstall script intent check (no clone) ==="
reinstall_cmd="$(grep '^git clone' "$SOURCE_DIR/bin/omarchy-reinstall-git")"
[[ $reinstall_cmd == *codeberg.org/malik-na/omarchy-mac* ]] \
  || fail "reinstall clone command does not target Codeberg: $reinstall_cmd"
[[ $reinstall_cmd == *"--branch main"* ]] \
  || fail "reinstall clone command should pin main branch: $reinstall_cmd"
pass "reinstall script targets Codeberg main"

echo
echo "=== Optional Omarchy install checks ==="
if [[ -d "${HOME}/.local/share/omarchy/.git" ]]; then
  live_origin="$(git -C "${HOME}/.local/share/omarchy" remote get-url origin 2>/dev/null || true)"
  echo "ℹ Live install origin: ${live_origin:-unknown}"
  echo "  To test redirect only (no pull):"
  echo "  OMARCHY_PATH=\"\$HOME/.local/share/omarchy\" git -C \"\$OMARCHY_PATH\" remote get-url origin"
  echo "  Run omarchy-update-git only after backing up: cp -a \"\$HOME/.local/share/omarchy\" \"\$HOME/.local/share/omarchy-backup-test\""
else
  echo "ℹ No live Omarchy install detected at ~/.local/share/omarchy"
fi

echo
echo "=== All safe validation checks passed ==="
