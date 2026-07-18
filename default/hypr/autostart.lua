-- Mac fork: lock screen on startup for enhanced security (malik-na, b52fd261).
-- Gated on display readiness: bare `hyprlock` here races GPU/DRM init at boot
-- on Apple Silicon and renders a blank, frozen lock surface. See the script.
o.exec_on_start("omarchy-mac-lock-on-boot")
o.launch_on_start("hypridle")
o.launch_on_start("mako")
o.exec_on_start("! omarchy-toggle-enabled waybar-off && " .. o.launch("waybar"))
o.launch_on_start("fcitx5 --disable notificationitem")
o.launch_on_start("swaybg -i ~/.config/omarchy/current/background -m fill")
o.exec_on_start("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
o.exec_on_start("omarchy-first-run")
o.exec_on_start("omarchy-powerprofiles-init")
o.launch_on_start("omarchy-hyprland-monitor-watch")

-- Mac fork: clipboard-history watchers (cliphist). Upstream dropped cliphist,
-- but omarchy-menu-clipboard depends on it.
o.exec_on_start("wl-paste --type text --watch cliphist store")
o.exec_on_start("wl-paste --type image --watch cliphist store")

-- Slow app launch fix -- set systemd vars.
o.exec_on_start("systemctl --user import-environment $(env | cut -d'=' -f 1)")
o.exec_on_start("dbus-update-activation-environment --systemd --all")

-- Run post-boot hooks after startup config has loaded.
o.exec_on_start("sleep 2 && omarchy-hook post-boot")
