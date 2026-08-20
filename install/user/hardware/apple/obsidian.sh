# obsidian in omarchy-base.packages is a pkgbase, not a package: its PKGBUILD
# declares pkgname=(${pkgbase}-{bin,appimage}). Asking for "obsidian" installs
# the dependencies -- fuse2, for the AppImage -- builds, and then installs
# nothing, because no package by that name exists. Apple Silicon therefore ends
# up with no Obsidian and an orphaned fuse2.
#
# Of the two outputs, obsidian-bin is arch=('x86_64') while obsidian-appimage
# carries aarch64 and extracts Obsidian's own arm64 AppImage, so ask for that
# one by name. Verified on an M2 Max: obsidian-appimage-1.12.7-1-aarch64 builds
# and runs.
if [[ $(uname -m) == "aarch64" ]] && omarchy-cmd-missing obsidian; then
  echo "Installing Obsidian for Apple Silicon (the AppImage build)."

  omarchy-pkg-aur-add obsidian-appimage ||
    echo "Warning: obsidian-appimage failed to build; install it later with 'omarchy pkg aur add obsidian-appimage'." >&2
fi
