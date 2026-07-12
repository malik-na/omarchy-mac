echo "Enable the Asahi display notch area (full panel height) on Apple Silicon"

# Apple Silicon (Asahi) only — appledrm is the display driver with show_notch.
modinfo appledrm &>/dev/null || exit 0

conf=/etc/modprobe.d/asahi-notch.conf
[[ -f $conf ]] && exit 0 # already configured

echo "options appledrm show_notch=1" | sudo tee "$conf" >/dev/null

# appledrm loads early, so bake the option into the initramfs, then flag reboot.
sudo mkinitcpio -P
omarchy-state set reboot-required
