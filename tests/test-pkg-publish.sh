#!/bin/bash
# Checks how omarchy-pkg-publish-aarch64 reads its target out of the pacman
# config. Getting this wrong publishes to the wrong place, or names the
# database something pacman will not fetch. Needs no root and no network.

set -uo pipefail

TOOL="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/omarchy-pkg-publish-aarch64"
CONF="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/default/pacman/pacman-stable.conf"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
pass=0
failures=0

# shellcheck source=/dev/null
source "$TOOL"
set +e # the script sets -e for its own run

check() {
  local label="$1"
  shift
  if "$@"; then
    echo "✓ $label"
    ((++pass))
  else
    echo "✗ $label"
    ((++failures))
  fi
}

not() {
  ! "$@"
}

echo "=== reading the release out of a Server line ==="

check "owner, repo and tag come back" \
  [ "$(parse_repo_server https://github.com/scottjones/omarchy-pkgs-aarch64/releases/download/edge)" \
    = "scottjones/omarchy-pkgs-aarch64 edge" ]

check "a different owner and tag work too" \
  [ "$(parse_repo_server https://github.com/malik-na/pkgs/releases/download/v1.2)" \
    = "malik-na/pkgs v1.2" ]

check "a non-GitHub server is refused" \
  not parse_repo_server https://example.com/arch/aarch64

check "a GitHub URL that is not a release is refused" \
  not parse_repo_server https://github.com/scottjones/omarchy-pkgs-aarch64

check "a missing tag is refused" \
  not parse_repo_server https://github.com/scottjones/omarchy-pkgs-aarch64/releases/download/

check "a tag with a slash is refused" \
  not parse_repo_server https://github.com/o/r/releases/download/edge/extra

echo
echo "=== reading the repo's own pacman config ==="

# The names here are what pacman fetches: get them wrong and every machine
# silently keeps building from source.
check "the section name is found" \
  [ "$(repo_name_from_conf "$CONF")" = "omarchy-aarch64" ]

check "the Server line is found" \
  [ -n "$(server_url_from_conf "$CONF")" ]

check "the shipped config parses into a real target" \
  [ -n "$(parse_repo_server "$(server_url_from_conf "$CONF")")" ]

echo
echo "=== a config with the section but no Server ==="

printf '[omarchy-aarch64]\nSigLevel = Optional TrustAll\n' >"$WORK/no-server.conf"
check "no Server means no target" \
  [ -z "$(server_url_from_conf "$WORK/no-server.conf")" ]

printf '[other]\nServer = https://github.com/o/r/releases/download/edge\n' >"$WORK/other.conf"
check "another section's Server is not picked up" \
  [ -z "$(server_url_from_conf "$WORK/other.conf")" ]

echo
echo "=== $pass checks passed, $failures failed ==="
(( failures == 0 ))
