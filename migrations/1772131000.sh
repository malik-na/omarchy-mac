#!/usr/bin/env bash

set -euo pipefail

echo "Mitigate fullscreen artifacts by disabling direct scanout"

looknfeel_conf="$HOME/.config/hypr/looknfeel.conf"

if [[ ! -f "$looknfeel_conf" ]]; then
  echo "No user looknfeel.conf found; skipping"
  exit 0
fi

if grep -Eq '^\s*direct_scanout\s*=\s*' "$looknfeel_conf"; then
  echo "direct_scanout already configured"
  exit 0
fi

cat >>"$looknfeel_conf" <<'EOF'

# Fullscreen artifact mitigation (Omarchy migration)
render {
    direct_scanout = 0
}
EOF

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo "Added render.direct_scanout = 0"
