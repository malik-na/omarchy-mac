echo "Point the aarch64 package repo at the omarchy-mac org"

# The [omarchy-aarch64] repo moved from a personal account to the project org.
# Fresh installs and channel switches copy the updated config wholesale, but an
# existing /etc/pacman.conf keeps whatever Server line it was installed with.
# GitHub redirects the old URL, so this is bookkeeping, not a repair.

old_server="Server = https://github.com/scottjones/omarchy-pkgs-aarch64/releases/download/edge"
new_server="Server = https://github.com/omarchy-mac/omarchy-pkgs-aarch64/releases/download/edge"

grep -qxF "$old_server" /etc/pacman.conf 2>/dev/null || exit 0

sudo sed -i "s|^$old_server\$|$new_server|" /etc/pacman.conf
