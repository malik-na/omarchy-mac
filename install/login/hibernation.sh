# Hibernation setup is Limine + btrfs + x86-oriented. On Apple Silicon (aarch64)
# Asahi, forced setup can fail install (non-btrfs) or leave useless Limine-only
# resume drop-ins that never apply via m1n1/u-boot/GRUB.
# limine-snapper is already skipped on non-x86_64, so --no-rebuild would never
# get a matching UKI rebuild on Mac either.
if [[ $(uname -m) == "aarch64" ]]; then
  echo "Skipping hibernation setup on aarch64 (not supported on Omarchy Mac / Asahi)"
  return 0 2>/dev/null || exit 0
fi

# Run before limine-snapper.sh so the resume hook + cmdline drop-ins are in
# place when `pacman -S limine-mkinitcpio-hook` triggers its single full UKI
# rebuild. The --no-rebuild flag tells the script to skip its own rebuild —
# limine-snapper's pacman install will produce a UKI that already includes
# hibernation.
omarchy-hibernation-setup --force --no-rebuild
