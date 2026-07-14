#!/bin/bash
# Walker/Elephant is not the launcher stack on Omarchy Mac (Apple Silicon).
# Fuzzel powers app launch, menus, clipboard history, and related pickers.
# Keep this script as a no-op so bin/omarchy-first-run stays in sync with upstream
# and never aborts under set -e when elephant is not installed.

echo "Skipping Elephant first-run setup (Omarchy Mac uses fuzzel)"
exit 0
