#!/bin/bash
omarchy-refresh-applications
update-desktop-database ~/.local/share/applications

# Open all images with imv
xdg-mime default imv.desktop image/png
xdg-mime default imv.desktop image/jpeg
xdg-mime default imv.desktop image/gif
xdg-mime default imv.desktop image/webp
xdg-mime default imv.desktop image/bmp
xdg-mime default imv.desktop image/tiff

# Open PDFs with the Document Viewer
xdg-mime default org.gnome.Evince.desktop application/pdf

# Set default browser based on installed desktop entries
choose_browser_desktop() {
  local candidate

  for candidate in \
    chromium.desktop \
    google-chrome.desktop \
    brave-browser.desktop \
    microsoft-edge.desktop \
    vivaldi-stable.desktop \
    org.mozilla.firefox.desktop \
    firefox.desktop; do
    if [[ -f "$HOME/.local/share/applications/$candidate" || -f "/usr/local/share/applications/$candidate" || -f "/usr/share/applications/$candidate" ]]; then
      printf "%s\n" "$candidate"
      return 0
    fi
  done

  return 1
}

browser_desktop="$(choose_browser_desktop || true)"
if [[ -n "$browser_desktop" ]]; then
  xdg-settings set default-web-browser "$browser_desktop"
  xdg-mime default "$browser_desktop" x-scheme-handler/http
  xdg-mime default "$browser_desktop" x-scheme-handler/https
else
  echo "[WARN] No supported browser desktop file found; skipping default browser setup"
fi

# Open video files with mpv
xdg-mime default mpv.desktop video/mp4
xdg-mime default mpv.desktop video/x-msvideo
xdg-mime default mpv.desktop video/x-matroska
xdg-mime default mpv.desktop video/x-flv
xdg-mime default mpv.desktop video/x-ms-wmv
xdg-mime default mpv.desktop video/mpeg
xdg-mime default mpv.desktop video/ogg
xdg-mime default mpv.desktop video/webm
xdg-mime default mpv.desktop video/quicktime
xdg-mime default mpv.desktop video/3gpp
xdg-mime default mpv.desktop video/3gpp2
xdg-mime default mpv.desktop video/x-ms-asf
xdg-mime default mpv.desktop video/x-ogm+ogg
xdg-mime default mpv.desktop video/x-theora+ogg
xdg-mime default mpv.desktop application/ogg

# Use Hey for mailto: links
xdg-mime default HEY.desktop x-scheme-handler/mailto

# Open text files with nvim
xdg-mime default nvim.desktop text/plain
xdg-mime default nvim.desktop text/english
xdg-mime default nvim.desktop text/x-makefile
xdg-mime default nvim.desktop text/x-c++hdr
xdg-mime default nvim.desktop text/x-c++src
xdg-mime default nvim.desktop text/x-chdr
xdg-mime default nvim.desktop text/x-csrc
xdg-mime default nvim.desktop text/x-java
xdg-mime default nvim.desktop text/x-moc
xdg-mime default nvim.desktop text/x-pascal
xdg-mime default nvim.desktop text/x-tcl
xdg-mime default nvim.desktop text/x-tex
xdg-mime default nvim.desktop application/x-shellscript
xdg-mime default nvim.desktop text/x-c
xdg-mime default nvim.desktop text/x-c++
xdg-mime default nvim.desktop application/xml
xdg-mime default nvim.desktop text/xml
