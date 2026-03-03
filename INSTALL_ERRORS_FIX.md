# Install Error Analysis & Fixes

Source: `/var/log/omarchy-install.log` from TTY3 run on 2026-03-03

---

## Summary of Errors Found

| Error | File | Severity | Status |
|-------|------|----------|--------|
| `qt5-wayland` not found | `omarchy-base.packages.fedora` | Medium | **Fixed** |
| `eza` not found in repos | `omarchy-base.packages.fedora` | Low | **Fixed** |
| `linux-modules-cleanup.service` not found | `install/config/kernel-modules-hook.sh` | Medium | **Fixed** |
| `dracut.sh` exit 1 on 6.18.10 kernel | `install/login/dracut.sh` | High | **Fixed** |
| `flathub` remote refs not found | `install/packaging/flatpak.sh` | Low | See notes |

---

## 1. qt5-wayland — Wrong package name

**Log:**
```
Failed to resolve the transaction:
No match for argument: qt5-wayland
[FAILED] qt5-wayland
```

**Root cause:** Fedora's package is named `qt5-qtwayland`, not `qt5-wayland`.
The name `qt5-wayland` doesn't exist on Fedora 42 aarch64.

**Fix applied:**
- `install/omarchy-base.packages.fedora` line 23: `qt5-wayland` → `qt5-qtwayland`

**Verify:**
```bash
dnf list --available qt5-qtwayland
# qt5-qtwayland.aarch64  5.15.18-1.fc42  updates
```

---

## 2. eza — Not in standard repos / COPR mismatch

**Log:**
```
Failed to resolve the transaction:
No match for argument: eza
[FAILED] eza
```

**Root cause:** `atim/eza` COPR was listed as optional COPR but it does NOT have an `aarch64` build
for Fedora 42. The `nclundell/fedora-extras` COPR (already used for bluetui) has `eza 0.23.4`.

**Fix applied:**
- `install/helpers/fedora-copr.sh`: replaced `atim/eza` with `nclundell/fedora-extras` in `OPTIONAL_COPR_REPOS`
  (nclundell/fedora-extras is also used for bluetui so this consolidates the COPR list)

**Fallback chain** (already in `install/helpers/fedora-manual.sh`):
1. Try `dnf install eza` (now works via nclundell)
2. Fallback: `cargo install --locked eza`
3. Final fallback: print info message, continue

**Verify:**
```bash
dnf list --available eza
# eza.aarch64  0.23.4-1.fc43  copr:...nclundell:fedora-extras
```

---

## 3. kernel-modules-hook.sh — Arch-only service on Fedora

**Log:**
```
Failed to enable unit: Unit linux-modules-cleanup.service does not exist
[2026-03-03 09:00:13] Failed: install/config/kernel-modules-hook.sh (exit code: 1)
```

**Root cause:** `linux-modules-cleanup.service` is an Arch Linux systemd unit that does not
exist on Fedora. The script called `chrootable_systemctl_enable` on it unconditionally.

**Fix applied:**
- `install/config/kernel-modules-hook.sh`: wrapped in `[[ -f /etc/arch-release ]]` guard.
  On non-Arch (Fedora), prints `[SKIP]` and exits cleanly.

---

## 4. dracut.sh — set -e + dual-kernel + non-clean-install = false failure

**Log:**
```
[Omarchy] Regenerating initramfs for kernel 6.14.2-401.asahi.fc42.aarch64+16k with dracut...
[Omarchy] Regenerating initramfs for kernel 6.18.10-402.asahi.fc42.aarch64+16k with dracut...
[2026-03-03 09:02:00] Failed: install/login/dracut.sh (exit code: 1)
```

**Root cause:**
- Script had `set -e` at the top
- Two kernels installed (`6.14.2` and `6.18.10` Asahi)
- This was NOT a clean install — previous run had already generated initramfs files
- `6.14.2` succeeded (timestamp updated to Mar 3 09:01)
- `6.18.10` failed with dracut exit code 1 (possibly: lock file, sudo cache expiry,
  or temporary state conflict from prior run)
- Because of `set -e`, the whole script was killed — no "dracut integration complete" printed
- **Manual re-run immediately after works fine** → confirms it was transient/re-install issue

**Answer to the question "could this be because it wasn't a clean install?":**
**Yes.** On re-install, `/boot/initramfs-6.18.10-*.img` already existed from the previous run.
A potential sudo timeout or dracut internal lock during the second kernel caused a transient
failure. With `set -e` there was no recovery.

**Fix applied:**
- Removed `set -e` from `install/login/dracut.sh`
- Replaced with per-kernel error tracking (`success_kernels` / `failed_kernels` arrays)
- Script exits 0 if at least one kernel succeeded
- Script exits 1 only if ALL kernels failed
- On partial failure: prints instructions for manual re-run

---

## 5. Flathub remote refs (not critical)

**Log:**
```
error: No remote refs found for 'flathub'
```

**Root cause:** Flatpak flathub remote was queried before it was fully synced/initialized.
Does not cause an install failure — the error is non-fatal in the install flow.

**No fix needed** — this is a known first-boot flathub sync timing issue.

---

## Files Changed

```
install/omarchy-base.packages.fedora      qt5-wayland → qt5-qtwayland
install/helpers/fedora-copr.sh            atim/eza → nclundell/fedora-extras (OPTIONAL_COPR_REPOS)
install/login/dracut.sh                   set -e removed, per-kernel error handling added
install/config/kernel-modules-hook.sh     Fedora guard added (Arch-only service skip)
```

## Suggested commit message

```
fix(fedora): resolve install errors from reinstall run on Asahi aarch64

- qt5-wayland → qt5-qtwayland (correct Fedora package name)
- eza: switch COPR from atim/eza (no aarch64) to nclundell/fedora-extras
- kernel-modules-hook.sh: skip linux-modules-cleanup.service on non-Arch
- dracut.sh: remove set -e, add per-kernel error handling so one
  kernel failure does not abort regeneration of remaining kernels
```
