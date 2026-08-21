#!/bin/bash
# The branded boot and unlock screens need three things to line up: the
# plymouth hook ahead of encrypt in HOOKS (omarchy_hooks.conf has it), splash
# on the kernel command line (alt-bootloaders.sh, which runs after this), and
# the Omarchy theme actually installed and selected.
#
# Nothing on a fresh install did the third. omarchy-refresh-plymouth is called
# by omarchy-reinstall, omarchy-reinstall-configs and the menu -- all of them
# things you run on a machine that is already set up -- so a new install booted
# with plymouth's stock theme and the passphrase prompt was unbranded.
#
# It installs the theme, selects it, and rebuilds the initramfs, which is what
# bundles the current theme into the image the unlock prompt draws from.
command -v plymouth-set-default-theme >/dev/null || return 0
omarchy-refresh-plymouth
