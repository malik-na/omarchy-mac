#!/bin/bash
set -euo pipefail

# this is ai slop generated proof of concept some poor dude on a broken system will have to test

PKGDIR="${1:-.}"

# Step 1: List all local packages by name
# Using pacman -Qip and %n prints package names
pkg_list="$PKGDIR/localpkg.lst"
> "$pkg_list"

for pkgfile in "$PKGDIR"/*.pkg.tar.*; do
    [[ -f "$pkgfile" ]] || continue
    sudo pacman -U --print --print-format %n "$pkgfile" >> "$pkg_list"
done

# Step 2: Remove any existing installation of these packages
while read -r pkg; do
    # skip empty lines
    [[ -z "$pkg" ]] && continue
    sudo pacman -Rns --noconfirm "$pkg" || true
done < "$pkg_list"

# Step 3: Generate install order using your installorder.sh script
install_order="$PKGDIR/install_order.txt"
chmod +x ./installorder.sh
./installorder.sh "$PKGDIR" > "$install_order"

# Step 4: Install packages in order
while read -r pkgpath; do
    [[ -z "$pkgpath" ]] && continue
    sudo pacman -U --noconfirm "$pkgpath"
done < "$install_order"

# Step 5: Generate IgnorePkg file (single line)
ignore_file="/etc/pacman/conf.d/omarchy_tmp_ignore"
sudo mkdir -p /etc/pacman/conf.d

# Read package names into a single line
ignore_line="IgnorePkg = $(paste -sd ' ' "$pkg_list")"

# Write to file
echo "$ignore_line" | sudo tee "$ignore_file" > /dev/null

echo "Temporary IgnorePkg updated at $ignore_file pls remember to remove when fixed"
