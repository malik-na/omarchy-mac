# Omarchy Mac: AI Development Guide

## Project Overview

Omarchy Mac is a macOS-like Linux desktop environment for Apple Silicon (M1/M2) Macs, built on top of Arch Linux ARM and Hyprland. It provides a polished, opinionated setup with fuzzel-based menus, theme management, and extensive automation scripts.

**Key Stack:** Bash scripts, Hyprland (Wayland compositor), Arch Linux ARM (aarch64), fuzzel (menu frontend), Waybar (status bar)

## Architecture

### Installation Flow
The installer follows a strict pipeline defined in `install.sh`:
1. **Preflight** (`install/preflight/all.sh`): Guards, locale, ARM mirrors, migrations, package manager setup
2. **Packaging** (`install/packaging/all.sh`): Install AUR helpers, base packages, fonts, LazyVim, webapps, TUIs
3. **Config** (`install/config/all.sh`): Theme setup, hardware detection, system tweaks, git/gpg config
4. **Login** (`install/login/all.sh`): User session configuration
5. **Post-install** (`install/post-install/all.sh`): Final cleanup and reboot

### Key Components

- **`bin/omarchy-*`**: Command utilities following `omarchy-<verb>-<noun>` naming (e.g., `omarchy-refresh-config`, `omarchy-pkg-install`)
- **`config/`**: Default configs deployed to `~/.config/` via `omarchy-refresh-config`
- **`themes/`**: Theme definitions with `fuzzel.ini`, `hypr/`, `waybar/` subdirs per theme
- **`migrations/`**: Unix timestamp-named scripts (`XXXXXXXXXX.sh`) tracked in `~/.local/state/omarchy/migrations/`
- **`install/helpers/`**: Reusable functions for logging, package management, presentation

### Critical Patterns

**Package Management Fallback Chain:**
```bash
# Always use this helper, never call pacman/yay/paru directly in scripts
omarchy_install_package_with_fallback "$package"  # Tries pacman → yay → paru
```

**Config Refresh System:**
```bash
# Deploys ~/.local/share/omarchy/config/X → ~/.config/X with automatic backup
omarchy-refresh-config hypr/hyprland.conf
omarchy-restart-waybar  # Always restart after refresh
```

**Logged Installation:**
```bash
# All install scripts run through this wrapper for centralized logging
run_logged $OMARCHY_INSTALL/packaging/fonts.sh
```

## Development Workflows

### Adding New Features

1. **New Command**: Create `bin/omarchy-<feature>` (no extension, executable)
2. **Config Changes**: Update files in `config/`, then create migration
3. **New Package**: Add to `install/omarchy-base.packages` (core) or `omarchy-other.packages` (optional)
4. **Theme Updates**: Modify all themes in `themes/*/`, ensure fuzzel compatibility

### Migration System

Create migrations for config changes, package additions, or structural updates:
```bash
omarchy-dev-add-migration  # Creates migrations/$(date +%s).sh
```

Migrations run once per user, tracked in `~/.local/state/omarchy/migrations/`. Include descriptive `echo` statements.

### Testing Changes

- **Dry runs**: Many scripts support `--dry-run` flag (e.g., `fix-mirrors.sh`)
- **Log inspection**: Check `/var/log/omarchy-install.log` for debugging
- **Architecture testing**: Always test aarch64-specific changes on real hardware
- **Menu testing**: Verify fuzzel integration (width flags, placeholder text, dmenu mode)

### ARM-Specific Considerations

- Architecture detected via `uname -m`: `aarch64` vs `x86_64`
- ARM mirrors handled specially in `install/preflight/arm-mirrors.sh`
- Skip x86_64-only hardware scripts (see `install/config/all.sh` conditionals)
- Fuzzel chosen over Walker for better aarch64 performance

## Code Conventions

### Bash Style

- Always use `#!/bin/bash` (not `/bin/sh`)
- Set safety flags: `set -euo pipefail` for robust scripts
- Export environment: `OMARCHY_PATH`, `OMARCHY_INSTALL`, `OMARCHY_INSTALL_LOG_FILE`
- Source helpers: `source "$OMARCHY_INSTALL/helpers/all.sh"` before using package functions

### Naming

- Scripts: `kebab-case` with `omarchy-` prefix
- Functions: `snake_case` with `omarchy_` prefix for public APIs
- Variables: `UPPER_SNAKE_CASE` for exports, `lower_snake_case` for locals

### Package Installation

```bash
# ❌ NEVER do this:
sudo pacman -S package-name

# ✅ Always use fallback chain:
omarchy_install_package_with_fallback "package-name"
# or from bin/:
omarchy-pkg-add package-name
```

### Config Deployment

```bash
# Backup-aware config refresh (auto-creates timestamped .bak files)
omarchy-refresh-config waybar/config.jsonc
# Then restart the service
omarchy-restart-waybar
```

## Key Files Reference

- `install.sh`: Main installer entry point
- `boot.sh`: Online installer (curl bootstrap)
- `fix-mirrors.sh`: Mirror repair utility with `--force`, `--backup` flags
- `bin/omarchy-menu`: Fuzzel-based application launcher
- `bin/omarchy-theme-set`: Theme switcher with auto-refresh
- `bin/omarchy-migrate`: Migration runner (called during preflight)
- `install/helpers/packages.sh`: Package management API
- `install/helpers/logging.sh`: `run_logged` function and log monitoring

## Integration Points

- **Hyprland**: Configs in `config/hypr/`, bindings use `$mainMod` (SUPER key)
- **Waybar**: Clock, battery, network status bar; configs in `config/waybar/`
- **Fuzzel**: Replaces Walker; menus defined in `bin/omarchy-menu` with width/prompt flags
- **systemd**: User services for background tasks (e.g., LocalSend via `systemd-run`)
- **gum**: TUI prompts for interactive installers (ensure installed in preflight)

## Common Tasks

**Add a new package:**
1. Add to `install/omarchy-base.packages` (after `OPTIONAL:` if optional)
2. Create migration if needed: `echo "omarchy-pkg-add new-package" > migrations/$(date +%s).sh`

**Update Hyprland config:**
1. Edit `config/hypr/hyprland.conf`
2. Create migration: `omarchy-refresh-config hypr/hyprland.conf && hyprctl reload`

**Add menu item:**
1. Edit `bin/omarchy-menu`, add case in relevant `show_*_menu` function
2. Follow existing pattern: `*Label*) command ;;`

**Fix architecture-specific bug:**
1. Check `uname -m` conditionals in `install/config/all.sh`
2. Use `[[ "$ARCH" == "aarch64" ]]` for ARM-only code

## Anti-Patterns

- ❌ Hardcoding package manager (use `omarchy_install_package_with_fallback`)
- ❌ Overwriting configs without backup (use `omarchy-refresh-config`)
- ❌ Skipping migrations for structural changes
- ❌ Using Walker instead of fuzzel (legacy, removed for aarch64 compatibility)
- ❌ Silent mirror overwrites (require `--force` flag or `OMARCHY_FORCE_MIRROR_OVERWRITE=1`)

## Resources

- **Support**: `@tiredkebab` on X (Twitter), Discord: https://discord.gg/KNQRk7dMzy
- **Log upload**: `omarchy-upload-log [install|this-boot|last-boot|installed]`
- **Original Omarchy**: https://github.com/dhh (this is the Apple Silicon fork)
- **Asahi Linux**: https://asahilinux.org/ (underlying hardware support)
