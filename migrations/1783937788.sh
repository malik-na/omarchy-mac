echo "Fix Signal launcher binary and restore cliamp Super+Shift+Alt+M binding"

BINDINGS="$HOME/.config/hypr/bindings.conf"
[[ -f $BINDINGS ]] || exit 0

# signal-desktop-beta is not packaged on aarch64; use signal-desktop
if grep -q 'signal-desktop-beta' "$BINDINGS"; then
  sed -i 's/signal-desktop-beta/signal-desktop/g' "$BINDINGS"
fi

# Restore cliamp binding if missing (Music webapp line is the Mac default)
if ! grep -q 'cliamp' "$BINDINGS"; then
  if grep -q 'SUPER SHIFT, M, Music,' "$BINDINGS"; then
    sed -i '/SUPER SHIFT, M, Music,/a bindd = SUPER SHIFT ALT, M, Music TUI, exec, omarchy-launch-or-focus-tui cliamp' "$BINDINGS"
  fi
fi
