# Omarchy Fedora Asahi Port — Roadmap

> This roadmap is based on the research and implementation strategy in Research.md. It is updated to reflect progress as of the current branch state and recent commits.

---

## Phase 1: Abstraction Layer & Environment Setup

- [x] 1.1 Create package mapping table (already complete)
- [x] 1.2 Build Fedora package list (install/omarchy-base.packages.fedora)
- [x] 1.3 Implement distro detection abstraction (install/helpers/distro.sh)
- [x] 1.4 Implement Fedora package helpers (install/helpers/packages-fedora.sh)
- [x] 1.5 Update install.sh and boot.sh to use abstraction layer
- [x] 1.6 Update fix-mirrors.sh to exit early on Fedora
- [x] 1.7 Audit and update all helpers/preflight scripts to use abstraction functions

## Phase 2: Script Porting & Package Handling

- [x] 2.1 Translate and maintain all package lists for Fedora (optional/build, etc.)
- [x] 2.2 Update all package install/remove/update logic in install/packaging, config, login, and post-install scripts to use omarchy_* abstraction
- [x] 2.3 Add logic for enabling and installing from COPR repositories (Fedora only)
- [x] 2.4 Add logic for manual install steps (Fedora only)
- [ ] 2.5 Update preflight/guard scripts for Fedora Asahi validation
- [ ] 2.6 Adapt any Arch-specific config/init logic (e.g., mkinitcpio → dracut)

## Phase 3: Testing, Integration & Documentation

- [ ] 3.1 Test installation and all features on Fedora Asahi Minimal
- [ ] 3.2 Debug and fix issues with package installs, configuration, and system integration
- [ ] 3.3 Update documentation (README, install guides) for Fedora-specific instructions
- [ ] 3.4 Document differences and known issues between Fedora and Arch versions
- [ ] 3.5 Prepare for release: final testing, changelog, and user instructions

---

## Progress Tracking

- Phase 1 is complete; all core abstractions and Fedora package helpers are in place and integrated into main scripts.
- Phase 2: Fedora package lists, COPR logic, and manual install logic are complete. Next actionable step: 2.5 (Update preflight/guard scripts for Fedora Asahi validation, with aarch64 compatibility as a priority).
- This roadmap will be updated with each completed step and commit.
