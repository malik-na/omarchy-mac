# Omarchy Mac Commit History Analysis

## Summary

The omarchy-mac repository's commit history shows it being 643 commits behind upstream (basecamp/omarchy) when comparing branches. This analysis identifies where and why the history diverged.

## Key Findings

### Initial Fork Point

The omarchy-mac fork was created from the upstream basecamp/omarchy repository at:

- **Commit**: `2df8c5f7`
- **Message**: "Install libyaml before attempting to install ruby (#1835)"
- **Date**: 2025-09-21

### Where the History Diverged

The history broke after commit `f634bfee` (upstream's v3.0.2 release) on **2025-09-28**.

#### Upstream's Path (correct first-parent chain):
```
f634bfee (v3.0.2) → a8f76783 → 1e859d37 → 6ee6dbaf → 73036988 → ... → upstream/master
```

#### Fork's Path (divergent):
```
f634bfee (v3.0.2) → 0ecd81e8 (README changes) → 47f5497d → 777f8385 → ... → origin/main
```

### Current Divergence Status

| Metric | Value |
|--------|-------|
| Fork behind upstream | 643 commits |
| Fork ahead of upstream | 205 commits |
| Common merge-base | `1e859d37` ("Fix comment") |
| Merge-base date | 2025-10-01 |

### Version Mismatch

The fork created its own versioning scheme:
- **Fork versions**: v3.2.0, v3.2.1, v3.2.2, v3.2.3
- **Upstream versions**: v3.0.0 → v3.0.1 → v3.0.2 → v3.1.0 → ... → v3.1.7 (latest)

The v3.2.x tags exist only in the fork and represent fork-specific releases.

## Root Cause Analysis

The divergence occurred because:

1. **Initial sync worked correctly**: The fork initially synced with upstream v3.0.2 (`f634bfee`)

2. **Fork-specific commits were added directly**: After syncing, fork-specific commits (like `0ecd81e8 Update README with Omarchy Menu installation details`) were committed directly to main

3. **Upstream continued evolving**: Meanwhile, upstream continued its development with commits like:
   - `1e859d37` - Fix comment (v3.0.2 continuation)
   - `6ee6dbaf` - Merge PR #2417
   - `73036988` - Update version
   - ... and hundreds more

4. **Merge commits didn't preserve first-parent**: When the fork later tried to sync with upstream, the merge commits didn't correctly integrate upstream's first-parent history

5. **Result**: Git calculates divergence by counting commits reachable from one branch but not the other. Due to the broken first-parent chain, many upstream commits appear "not merged" even though their changes may be present.

## Commits Timeline (Around Divergence Point)

### On Fork (origin/main) after f634bfee:
```
152: f634bfee 2025-09-28 Merge pull request #2048 from basecamp/dev (v3.0.2)
151: 0ecd81e8 2025-09-28 Update README with Omarchy Menu installation details  ← FORK DIVERGES HERE
150: 47f5497d 2025-09-28 Revise Omarchy Menu section in README
149: 777f8385 2025-09-28 Add mise-work script and update package list for ARM64 support
...
```

### On Upstream (upstream/master) after f634bfee:
```
27: f634bfee 2025-09-28 Merge pull request #2048 from basecamp/dev (v3.0.2)
26: a8f76783 2025-09-28 Merge pull request #2050  ← UPSTREAM CONTINUES HERE
25: 1e859d37 2025-10-01 Fix comment
24: 6ee6dbaf 2025-10-05 Merge pull request #2417
...
```

## Potential Solutions

### Option 1: Fresh Sync (Recommended for clean history)
1. Create a new branch from current `upstream/master`
2. Cherry-pick or reapply only the Mac-specific changes from the fork
3. Replace `main` with this new clean branch

### Option 2: Merge and Accept History
1. Merge `upstream/master` into `main`
2. Accept that the history will remain complex
3. Move forward with regular upstream syncs

### Option 3: Rebase (Complex, may cause conflicts)
1. Rebase fork-specific commits onto `upstream/master`
2. Force-push to `main`
3. Note: This rewrites history and may break existing clones

## Commands Used for Analysis

```bash
# Find common ancestor
git merge-base origin/main upstream/master
# Result: 1e859d37cb7fef6ac687442dc1fe515d01d1302d

# Count divergence
git rev-list --count origin/main..upstream/master  # 643 behind
git rev-list --count upstream/master..origin/main  # 205 ahead

# Find first fork-specific commit (parent is 2df8c5f7)
git log --oneline origin/main | grep "adjusted scripts for ARM64"
# Result: 15e3b6b3 adjusted scripts for ARM64 - First Mac-specific commit

# View divergence point
git log --oneline origin/main | sed -n '145,160p'
```
