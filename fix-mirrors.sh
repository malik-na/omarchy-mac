#!/usr/bin/env bash
# fix-mirrors.sh
# Safe helper to ensure proper pacman configuration and mirrors are set up
# Supports: --replace (force overwrite), --prefer (place Omarchy servers at top),
# --backup (create timestamped backup), --dry-run (show actions, don't write)
# Usage: sudo ./fix-mirrors.sh [--replace] [--prefer] [--backup] [--dry-run]

set -euo pipefail

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
  "x86_64") PACMAN_ARCH="x86_64" ;;
  "aarch64") PACMAN_ARCH="aarch64" ;;
  *)
    echo "[ERROR] Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

# Setup pacman.conf first
cat >/tmp/pacman.conf <<"EOL"
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives

#
# GENERAL OPTIONS
#
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.
#RootDir     = /
#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
HoldPkg     = pacman glibc
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
#CleanMethod = KeepInstalled
Architecture = PACMAN_ARCH_PLACEHOLDER

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
#UseSyslog
#Color
#NoProgressBar
CheckSpace
#VerbosePkgLists
ParallelDownloads = 5

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have $repo replaced by the name of the current repo
#   - URLs will have $arch replaced by the name of the architecture
#
# Repository entries are of the format:
#       [repo-name]
#       Server = ServerName
#       Include = IncludePath
#
# The header [repo-name] is crucial - it must be present and
# uncommented to enable the repo.
#

# The testing repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

EOL

# Add architecture-specific repositories
if [[ "$PACMAN_ARCH" == "aarch64" ]]; then
  cat >>/tmp/pacman.conf <<'AARCH64_REPOS'
[asahi-alarm]
Include = /etc/pacman.d/mirrorlist.asahi-alarm

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[alarm]
Include = /etc/pacman.d/mirrorlist

[aur]
Include = /etc/pacman.d/mirrorlist
AARCH64_REPOS
else
  cat >>/tmp/pacman.conf <<'X86_64_REPOS'
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
X86_64_REPOS
fi

# Replace the architecture placeholder with the actual architecture
sed -i "s/PACMAN_ARCH_PLACEHOLDER/$PACMAN_ARCH/g" /tmp/pacman.conf

# Install the pacman.conf if it doesn't match
if ! cmp -s /tmp/pacman.conf /etc/pacman.conf; then
  echo "Installing new pacman.conf..."
  sudo cp /tmp/pacman.conf /etc/pacman.conf
fi
rm -f /tmp/pacman.conf

SRC="$HOME/.local/share/omarchy/default/pacman/mirrorlist"
DEST="/etc/pacman.d/mirrorlist"
REPLACE=0
PREFER=0
BACKUP=0
DRYRUN=0
COUNTRY=us
REMOVE_OMARCHY=1

usage() {
  cat <<EOF
Usage: sudo $0 [--replace] [--prefer] [--backup] [--dry-run]

Options:
  --replace   Replace the destination mirrorlist with Omarchy's bundled file (after optional backup).
  --prefer    Ensure Omarchy's Server lines are placed at the top of the mirrorlist (preserve others below).
  --backup    Create a timestamped backup of the destination if it exists.
  --dry-run   Show what would be done without modifying files.

Default behavior: merge Omarchy's Server lines into existing mirrorlist, appending missing entries.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --replace)
      REPLACE=1
      shift
      ;;
    --prefer)
      PREFER=1
      shift
      ;;
    --backup)
      BACKUP=1
      shift
      ;;
    --dry-run)
      DRYRUN=1
      shift
      ;;
    --country)
      COUNTRY=${2:-us}
      shift 2
      ;;
    --remove-omarchy)
      REMOVE_OMARCHY=1
      shift
      ;;
    --keep-omarchy)
      REMOVE_OMARCHY=0
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! -f "$SRC" ]]; then
  echo "[WARN] Omarchy bundled mirrorlist not found at: $SRC (Omarchy server removal will be skipped)" >&2
  SRC=""
fi

if [[ ! -f "$DEST" ]]; then
  if [[ "$PACMAN_ARCH" == "aarch64" ]]; then
    echo "[INFO] Destination $DEST does not exist. Will create a mirrorlist with Arch Linux ARM servers."
    if [[ $DRYRUN -eq 1 ]]; then
      echo "[DRYRUN] Would write Arch Linux ARM servers to $DEST"
      exit 0
    fi
    # Build a minimal Arch Linux ARM mirror entry based on COUNTRY
    arch_servers=("Server = http://$COUNTRY.mirror.archlinuxarm.org/\$arch/\$repo" "Server = http://mirror.archlinuxarm.org/\$arch/\$repo")
  else
    echo "[INFO] Destination $DEST does not exist. Will create a mirrorlist with Arch Linux servers."
    if [[ $DRYRUN -eq 1 ]]; then
      echo "[DRYRUN] Would write Arch Linux servers to $DEST"
      exit 0
    fi
    # Build a minimal Arch Linux mirror entry based on COUNTRY
    arch_servers=("Server = http://$COUNTRY.mirror.archlinux.org/\$repo/os/\$arch" "Server = http://mirror.archlinux.org/\$repo/os/\$arch")
  fi
  # Write the servers (simple form)
  tmp=$(mktemp)
  for s in "${arch_servers[@]}"; do
    echo "$s" >>"$tmp"
  done
  sudo cp "$tmp" "$DEST"
  rm -f "$tmp"
  echo "[OK] Created $DEST with appropriate servers for $PACMAN_ARCH architecture"
  exit 0
fi

# At this point, DEST exists.
if [[ $BACKUP -eq 1 ]]; then
  bak="$DEST.bak.$(date +%Y%m%d%H%M%S)"
  if [[ $DRYRUN -eq 1 ]]; then
    echo "[DRYRUN] Would backup $DEST -> $bak"
  else
    sudo cp "$DEST" "$bak"
    echo "[OK] Backed up existing mirrorlist to: $bak"
  fi
fi

if [[ $REPLACE -eq 1 ]]; then
  if [[ $DRYRUN -eq 1 ]]; then
    echo "[DRYRUN] Would replace $DEST with $SRC"
  else
    sudo cp "$SRC" "$DEST"
    echo "[OK] Replaced $DEST with bundled mirrorlist"
  fi
  exit 0
fi

##############################################
# New behavior: prioritize Arch Linux ARM and
# remove Omarchy servers by default
##############################################

# Collect existing server lines from DEST
mapfile -t dest_servers < <(grep -E '^\s*Server\s*=' "$DEST" || true)

normalize() { echo "$1" | sed -E 's/\s+/ /g' | sed -E 's/^\s+|\s+$//g'; }

# Filter out Omarchy servers from dest if requested
filtered_dest=()
for s in "${dest_servers[@]}"; do
  if [[ $REMOVE_OMARCHY -eq 1 ]]; then
    if echo "$s" | grep -qi 'omarchy'; then
      # skip Omarchy servers
      echo "[INFO] Removing Omarchy server from list: $s"
      continue
    fi
  fi
  filtered_dest+=("$s")
done

# Build desired servers based on architecture
if [[ "$PACMAN_ARCH" == "aarch64" ]]; then
  arch_servers=("Server = http://$COUNTRY.mirror.archlinuxarm.org/\$arch/\$repo" "Server = http://mirror.archlinuxarm.org/\$arch/\$repo")
else
  arch_servers=("Server = http://$COUNTRY.mirror.archlinux.org/\$repo/os/\$arch" "Server = http://mirror.archlinux.org/\$repo/os/\$arch")
fi

# Build set of existing servers for lookup
declare -A have
for s in "${filtered_dest[@]}"; do
  have["$(normalize "$s")"]=1
done

# Find which arch servers are missing
missing_arch=()
for s in "${arch_servers[@]}"; do
  key=$(normalize "$s")
  if [[ -z "${have[$key]:-}" ]]; then
    missing_arch+=("$s")
  fi
done

if [[ ${#missing_arch[@]} -eq 0 && ${#filtered_dest[@]} -eq ${#dest_servers[@]} ]]; then
  echo "[OK] No changes required; appropriate servers for $PACMAN_ARCH present and Omarchy servers removed."
  exit 0
fi

# If prefer, put arch servers at top and then the filtered existing servers
if [[ $PREFER -eq 1 ]]; then
  combined_servers=()
  for s in "${arch_servers[@]}"; do combined_servers+=("$s"); done
  for s in "${filtered_dest[@]}"; do
    key=$(normalize "$s")
    # avoid duplicates
    exists=0
    for cs in "${combined_servers[@]}"; do
      if [[ "$(normalize "$cs")" == "$key" ]]; then
        exists=1
        break
      fi
    done
    if [[ $exists -eq 0 ]]; then combined_servers+=("$s"); fi
  done

  if [[ $DRYRUN -eq 1 ]]; then
    echo "[DRYRUN] Would write preferred servers for $PACMAN_ARCH at top of $DEST:"
    for s in "${combined_servers[@]}"; do echo "  $s"; done
    exit 0
  fi

  tmp=$(mktemp)
  grep -v -E '^\s*Server\s*=' "$DEST" >"$tmp".body || true
  {
    for s in "${combined_servers[@]}"; do echo "$s"; done
    cat "$tmp".body
  } | sudo tee "$DEST" >/dev/null
  rm -f "$tmp".body
  echo "[OK] Wrote preferred servers for $PACMAN_ARCH to $DEST"
  exit 0
fi

# Default: append any missing arch servers after existing filtered servers
if [[ $DRYRUN -eq 1 ]]; then
  echo "[DRYRUN] Would remove Omarchy servers and append missing servers for $PACMAN_ARCH to $DEST"
  echo "[DRYRUN] Servers to append:"
  for s in "${missing_arch[@]}"; do echo "  $s"; done
  exit 0
fi

# Reconstruct DEST: preserve non-Server lines, keep filtered_dest, then append missing_arch
tmp=$(mktemp)
grep -v -E '^\s*Server\s*=' "$DEST" >"$tmp".body || true
{
  for s in "${filtered_dest[@]}"; do echo "$s"; done
  for s in "${missing_arch[@]}"; do echo "$s"; done
  cat "$tmp".body
} | sudo tee "$DEST" >/dev/null
rm -f "$tmp".body

echo "[OK] Updated $DEST: removed Omarchy servers (if any) and ensured appropriate servers for $PACMAN_ARCH present"
exit 0
