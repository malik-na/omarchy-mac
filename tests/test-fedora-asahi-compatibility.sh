#!/bin/bash

set -euo pipefail

echo "=== Fedora Asahi compatibility test ==="

[[ -f /etc/fedora-release ]] || {
  echo "[FAIL] /etc/fedora-release not found"
  exit 1
}

[[ "$(uname -m)" == "aarch64" ]] || {
  echo "[FAIL] expected aarch64, got $(uname -m)"
  exit 1
}

grep -qi asahi /proc/version || {
  echo "[FAIL] Asahi kernel marker not found in /proc/version"
  exit 1
}

for cmd in dnf rpm dracut; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[FAIL] required command not found: $cmd"
    exit 1
  }
done

echo "[OK] Fedora Asahi aarch64 environment looks compatible"
