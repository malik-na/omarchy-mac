# Omarchy-Mac → Fedora Asahi Remix: Porting Research

## Executive Summary
- Omarchy-mac is tailored to Arch/Asahi Alarm with extensive use of `pacman`, AUR helpers (`yay`/`paru`), and `makepkg`. Porting to Fedora Asahi Remix requires reworking package management, repository handling, preflight/migration scripts, and Arch-specific package selections to Fedora’s DNF/RPM ecosystem, using COPR/Flatpak/source RPMs where needed.
- Fedora Asahi Remix (based on Fedora 42) integrates Asahi platform packages upstream and delivers a polished Wayland-first experience. Advanced audio DSP (Bankstown + speakersafetyd) and conformant graphics are included. The port should align with Fedora conventions (DNF, `.repo` files, SELinux, `dracut`) while preserving current Omarchy UX.

## Platform Differences
- **Package manager:** Arch `pacman` + AUR (`yay`/`paru`) vs Fedora `dnf` + `rpm`; third‑party via COPR, Flatpak, or source RPMs.
- **Repository config:** Arch `/etc/pacman.conf` + `/etc/pacman.d/mirrorlist` vs Fedora `/etc/yum.repos.d/*.repo` + `/etc/dnf/dnf.conf` and `dnf config-manager`.
- **Build tooling:** Arch `makepkg`/PKGBUILD vs Fedora `rpmbuild`/`mock` + `dnf builddep`.
- **Initramfs:** Arch `mkinitcpio` vs Fedora `dracut`.
- **Security model:** SELinux enforcing on Fedora may impact scripts/services (contexts, policies).
- **Asahi integration:** Arch (Alarm) ships `linux-asahi` and related packages; Fedora Asahi Remix integrates Asahi support upstream (Fedora 42).
- **Desktop:** Both Wayland‑first; Fedora ships KDE Plasma 6.3 and GNOME 48; Hyprland available in Fedora.

## Command Mapping (Common Actions)
- **System update:** `pacman -Syu` → `dnf upgrade -y` (or `dnf distro-sync -y`).
- **Install package:** `pacman -S <pkg>` → `dnf install -y <pkg>`.
- **Remove package:** `pacman -Rs <pkg>` → `dnf remove -y <pkg>`.
- **Search packages:** `pacman -Ss <term>` → `dnf search <term>`.
- **Info (remote/local):** `pacman -Si/-Qi` → `dnf info <pkg>` (remote/local) and `rpm -qi <pkg>` (local).
- **List files (remote/local):** `pacman -Fl/-Ql` → `dnf repoquery -l <pkg>` or `rpm -ql <pkg>`.
- **Provides (owns file):** `pacman -F <file>` → `dnf provides <file>`.
- **Install local file:** `pacman -U <file.pkg.tar.zst>` → `dnf install <file.rpm>`.
- **Clean cache:** `pacman -Sc/-Scc` → `dnf clean all`.
- **Orphans:** `pacman -Qdtq` (+ `pacman -Rs`) → `dnf autoremove -y`.
- **Repo refresh:** `pacman -Sy` → `dnf check-update` or `dnf upgrade --refresh`.

## File Impact Matrix (Workspace)
- **boot.sh:** [boot.sh#L41](boot.sh#L41) uses `sudo pacman -Syu --noconfirm --needed git` → change to `dnf upgrade -y` + `dnf install -y git`.
- **install/helpers/packages.sh:**
  - Presence checks: [install/helpers/packages.sh#L1-L20](install/helpers/packages.sh#L1-L20) use `pacman -Qi/-Si`.
  - Install paths: [install/helpers/packages.sh#L73-L96](install/helpers/packages.sh#L73-L96) implement `pacman`/`yay`/`paru` installs.
  - AUR helpers: [install/helpers/packages.sh#L110-L146](install/helpers/packages.sh#L110-L146) ensure `yay`/`paru` via `makepkg`.
  - Action: replace with `dnf` + `rpm` queries; add COPR enable (`dnf copr enable`), Flatpak fallback; remove `makepkg` flow.
- **fix-mirrors.sh:**
  - Pacman config scaffold: [fix-mirrors.sh#L1-L30](fix-mirrors.sh#L1-L30).
  - Asahi Alarm mirrorlist references: [fix-mirrors.sh#L90-L101](fix-mirrors.sh#L90-L101).
  - Writes `pacman.conf`/mirrorlist: [fix-mirrors.sh#L123-L133](fix-mirrors.sh#L123-L133).
  - Action: replace with Fedora `.repo` checks under `/etc/yum.repos.d/`; drop mirrorlist logic.
- **install/omarchy-base.packages:** [install/omarchy-base.packages#L9-L40](install/omarchy-base.packages#L9-L40) contains Arch/Asahi names (e.g., `linux-asahi`, `asahi-desktop-meta`, `mesa-utils`) → remap to Fedora equivalents/groups; mark COPR/Flatpak.
- **install/preflight/all.sh:** [install/preflight/all.sh#L1-L10](install/preflight/all.sh#L1-L10) invokes `preflight/pacman.sh` and mkinitcpio disabling → replace with Fedora `preflight/dnf.sh`; remove mkinitcpio logic; add `dracut`/SELinux sanity.
- **bin/omarchy-update-system-pkgs:** [bin/omarchy-update-system-pkgs#L1-L35](bin/omarchy-update-system-pkgs#L1-L35) uses `yay -Syu` and `pacman` orphan removal → change to `dnf upgrade -y` + `dnf autoremove -y`.
- **bin/omarchy-pkg-install:** [bin/omarchy-pkg-install#L1-L22](bin/omarchy-pkg-install#L1-L22) lists via `pacman -Slq` and installs via `pacman -S` → switch to `dnf list/search` + `dnf install` (retain `fzf` UX).
- **bin/omarchy-pkg-aur-install:** [bin/omarchy-pkg-aur-install#L1-L30](bin/omarchy-pkg-aur-install#L1-L30) is `yay`-centric → replace with COPR enable + `dnf install`, or Flatpak TUI flow.
- **migrations/1755920552.sh:** [migrations/1755920552.sh#L1-L6](migrations/1755920552.sh#L1-L6) edits `/etc/pacman.conf` → translate to `.repo`/`dnf.conf` adjustments.

## Dependency Mapping (Arch → Fedora Strategy)
- **linux-asahi / linux-asahi-headers:** Native (Fedora Asahi Remix upstream kernel; verify package names).
- **asahi-desktop-meta:** Native (Remix image/groups; KDE Plasma 6.3/GNOME 48).
- **asahi-fwextract:** Native (firmware handled by Remix).
- **mesa / mesa-utils / mesa-demos:** Native (`mesa-*` in Fedora).
- **fwupd:** Native.
- **grub / efibootmgr:** Native (standard Fedora tooling).
- **alacritty:** Native.
- **ghostty:** COPR or Flatpak (depending on availability).
- **waybar / mako / fuzzel:** Native.
- **hyprland / hypridle / hyprlock / hyprpicker:** Native or COPR (prefer native; use COPR if needed).
- **fcitx5 (+ gtk/qt) / fontconfig / noto-fonts:** Native (Fedora typically `google-noto-*`).
- **neovim (nvim):** Native.
- **imv / kdenlive / evince / ffmpegthumbnailer:** Native.
- **docker / docker-compose / buildx:** Native (consider Podman as alternative).
- **localsend / obsidian:** Flatpak.
- **satty:** COPR/Source; alternative `swappy` (Native).
- **wl-screenrec:** COPR/Source; alternative `wf-recorder` (Native).
- **tzupdate:** `pipx`/`pip` install.
- **python-terminaltexteffects:** Native if packaged; else `pipx`/`pip`.

## Asahi Hardware Support on Fedora
- **Upstream integration:** Asahi platform packages are in Fedora 42 (Remix), maintained in collaboration with Asahi Linux.
- **Graphics:** Conformant OpenGL 4.6, OpenGL ES 3.2, OpenCL 3.0, Vulkan 1.4 via Mesa; 100% Wayland experience; XWayland for legacy apps.
- **Displays:** Local dimming supported on 14"/16" MBP; HDR/120Hz not yet supported.
- **Audio DSP:** Integrated DSP via PipeWire/WirePlumber; Bankstown bass enhancement; Smart Amp via `speakersafetyd`.
- **Devices:** Broad M1/M2 support (MacBook Air/Pro/Mini/Studio/iMac); Wi‑Fi, Bluetooth, USB‑C displays, Thunderbolt/USB4, camera, keyboard/trackpad.

## Risks & Mitigations
- **AUR removal:** Loss of `yay`/`paru` workflows → Use COPR, Flatpak, or source RPMs.
- **Package name drift:** Arch→Fedora name differences → Maintain mapping and automated resolver.
- **Repo management:** `pacman.conf`/mirrorlist → `.repo` files and `dnf config-manager`; add preflight validation.
- **SELinux:** Enforcing may affect scripts/services → Preflight checks, ensure correct file contexts; use `policycoreutils`.
- **Initramfs:** `mkinitcpio` assumptions → Use `dracut`; update migration scripts.
- **Audio stack variations:** Ensure Asahi DSP profiles load; verify `speakersafetyd` service.
- **Orphan cleanup:** `dnf autoremove` may remove desired packages → Use `dnf mark install` or keep-lists.

## Roadmap Phases
- **1. Audit & Plan:** Inventory Arch-specific paths; confirm Fedora availability/COPR/Flatpak for dependencies.
- **2. Package Abstraction:** Implement `dnf` abstraction; retire AUR helpers; add COPR/Flatpak integration.
- **3. Repo/Preflight Port:** Replace pacman preflight/mirror logic with `.repo` management and `dnf` checks; add SELinux/`dracut` sanity.
- **4. Migration Scripts:** Translate pacman.conf edits to `.repo`/`dnf.conf`; adjust boot/init tooling and systemd units as needed.
- **5. Desktop & Audio Validation:** Validate Wayland + Hyprland/KDE/GNOME; verify Bankstown + `speakersafetyd` per model.
- **6. QA & Release:** Handle orphans, rollback via `dnf history`; smoke tests across supported Apple Silicon devices.

## References
- Fedora Asahi Remix: https://asahilinux.org/fedora/
- Pacman↔DNF mappings (Arch Wiki): https://wiki.archlinux.org/title/Pacman/Rosetta
- DNF vs APT (Fedora Quick Docs): https://docs.fedoraproject.org/en-US/quick-docs/dnf-vs-apt/
- Audio DSP – Bankstown: https://github.com/chadmed/bankstown
- Audio DSP – speakersafetyd: https://github.com/AsahiLinux/speakersafetyd

## Workspace Evidence (Arch-specific usage)
- [boot.sh#L41](boot.sh#L41) has pacman usage.
- [install/helpers/packages.sh#L1-L20](install/helpers/packages.sh#L1-L20) shows pacman presence checks; [install/helpers/packages.sh#L73-L96](install/helpers/packages.sh#L73-L96) performs installs via pacman/yay/paru; [install/helpers/packages.sh#L110-L146](install/helpers/packages.sh#L110-L146) ensures AUR helpers.
- [fix-mirrors.sh#L1-L30](fix-mirrors.sh#L1-L30) initializes pacman.conf; [fix-mirrors.sh#L90-L101](fix-mirrors.sh#L90-L101) references [asahi-alarm] mirrorlist; [fix-mirrors.sh#L123-L133](fix-mirrors.sh#L123-L133) writes pacman.conf and mirrorlist.
- [install/omarchy-base.packages#L9-L40](install/omarchy-base.packages#L9-L40) contains Arch/Asahi-specific package names.
- [install/preflight/all.sh#L1-L10](install/preflight/all.sh#L1-L10) calls pacman preflight and mkinitcpio disable.
- [bin/omarchy-update-system-pkgs#L1-L35](bin/omarchy-update-system-pkgs#L1-L35) uses `yay` and `pacman` orphan removal.
- [bin/omarchy-pkg-install#L1-L22](bin/omarchy-pkg-install#L1-L22) and [bin/omarchy-pkg-aur-install#L1-L30](bin/omarchy-pkg-aur-install#L1-L30) use `pacman`/`yay` for interactive flows.
- [migrations/1755920552.sh#L1-L6](migrations/1755920552.sh#L1-L6) edits `pacman.conf`.
