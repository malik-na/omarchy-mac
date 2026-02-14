echo "Update Chromium default desktop entry to ensure Wayland browser defaults"

if [[ -f /usr/share/applications/chromium-browser.desktop ]]; then
  browser_desktop="chromium-browser.desktop"
else
  browser_desktop="chromium.desktop"
fi

xdg-settings set default-web-browser "$browser_desktop"
xdg-mime default "$browser_desktop" x-scheme-handler/http
xdg-mime default "$browser_desktop" x-scheme-handler/https
