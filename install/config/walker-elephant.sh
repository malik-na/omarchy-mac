# Walker/Elephant is not the launcher stack on Omarchy Mac (Apple Silicon).
# Fuzzel powers app launch, menus, clipboard history, and related pickers.
# Keep this script as a no-op so install/config/all.sh stays in sync with upstream.

echo "Skipping Walker/Elephant setup (Omarchy Mac uses fuzzel)"
return 0 2>/dev/null || true
