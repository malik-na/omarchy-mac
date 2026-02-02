#!/bin/bash
echo "Migrate fuzzel configs: replace terminal=foot with terminal=\$TERMINAL"

STATE_DIR="$HOME/.local/state/omarchy/migrations"
mkdir -p "$STATE_DIR"

FILES=(
  "$HOME/.config/fuzzel/fuzzel.ini"
  "$HOME/.config/fuzzel/themes" # directory - will process files inside
  "$HOME/.local/share/omarchy/config/fuzzel/fuzzel.ini"
  # Also update any user themes in omarchy config path
  "$HOME/.config/omarchy/themes"
)

backup() {
  local f="$1"
  if [ -f "$f" ]; then
    cp -a "$f" "$f".bak-$(date +%s)
  fi
}

replace_in_file() {
  local f="$1"
  if [ -f "$f" ] && grep -q "^terminal=foot$" "$f"; then
    backup "$f"
    sed -i 's/^terminal=foot$/terminal=\\$TERMINAL/' "$f"
    echo "Updated $f"
  fi
}

for p in "${FILES[@]}"; do
  if [ -f "$p" ]; then
    replace_in_file "$p"
  elif [ -d "$p" ]; then
    # iterate .ini files
    for f in "$p"/*.ini; do
      [ -f "$f" ] || continue
      replace_in_file "$f"
    done
  fi
done

# If a resolved TERMINAL value is available, replace literal $TERMINAL with its value
resolved_terminal="${TERMINAL:-}"
# Try to source uwsm default if available and terminal not set
if [ -z "$resolved_terminal" ] && [ -f "$HOME/.config/uwsm/default" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.config/uwsm/default"
  resolved_terminal="${TERMINAL:-}"
fi

if [ -n "$resolved_terminal" ]; then
  echo "Resolving \$TERMINAL to '$resolved_terminal' in user fuzzel configs"
  replace_resolved() {
    local f="$1"
    if [ -f "$f" ] && grep -q "^terminal=\\\$TERMINAL$" "$f"; then
      backup "$f"
      # Replace literal $TERMINAL with resolved terminal name
      sed -i "s|^terminal=\\\$TERMINAL$|terminal=${resolved_terminal}|" "$f" 2>/dev/null || true
      echo "Resolved $f"
    fi
  }

  for p in "${FILES[@]}"; do
    if [ -f "$p" ]; then
      replace_resolved "$p"
    elif [ -d "$p" ]; then
      for f in "$p"/*.ini; do
        [ -f "$f" ] || continue
        replace_resolved "$f"
      done
    fi
  done
fi

touch "$STATE_DIR/1768950000_replace_fuzzel_terminal_foot_with_terminal_var.sh"
echo "Migration complete."
