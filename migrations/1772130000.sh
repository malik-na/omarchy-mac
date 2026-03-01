#!/usr/bin/env bash

set -euo pipefail

echo "Ensure SUPER+RETURN launches terminal"

bindings_conf="$HOME/.config/hypr/bindings.conf"
expected='bindd = SUPER, RETURN, Terminal, exec, uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"'

if [[ ! -f "$bindings_conf" ]]; then
  echo "No user bindings.conf found; skipping"
  exit 0
fi

if grep -Fq "$expected" "$bindings_conf"; then
  echo "Terminal binding already correct"
  exit 0
fi

if grep -Eq '^bindd\s*=\s*SUPER,\s*RETURN,\s*Terminal,\s*exec,' "$bindings_conf"; then
  sed -i -E "s|^bindd\s*=\s*SUPER,\s*RETURN,\s*Terminal,\s*exec,.*$|$expected|" "$bindings_conf"
  echo "Updated existing terminal binding"
else
  tmp_file="$(mktemp)"
  {
    echo "# Application bindings"
    echo "$expected"
    cat "$bindings_conf"
  } >"$tmp_file"
  mv "$tmp_file" "$bindings_conf"
  echo "Added missing terminal binding"
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi
