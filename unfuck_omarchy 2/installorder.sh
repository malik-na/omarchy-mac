#!/bin/bash
# generate-install-order.sh
# Usage: ./generate-install-order.sh /path/to/local_pkgs > install_order.txt

PKGDIR="${1:-.}"

# Check directory exists
if [[ ! -d "$PKGDIR" ]]; then
    echo "Directory $PKGDIR not found." >&2
    exit 1
fi

declare -A pkg_deps
declare -A pkg_names
all_pkgs=()

# Step 1: Gather package names and dependencies
for pkgfile in "$PKGDIR"/*.pkg.tar.*; do
    [[ -f "$pkgfile" ]] || continue
    # Extract package name
    name=$(pacman -Qip "$pkgfile" | awk -F': ' '/^Name/{print $2}')
    pkg_names["$name"]="$pkgfile"
    all_pkgs+=("$name")
    
    # Extract dependencies (ignore version numbers)
    deps=$(pacman -Qip "$pkgfile" | awk -F': ' '/^Depends/{print $2}' | sed 's/[<>>=].*//g' | tr ' ' '\n')
    pkg_deps["$name"]="$deps"
done

# Step 2: Topological sort to determine install order
install_order=()
while ((${#all_pkgs[@]})); do
    progress=0
    remaining=()
    
    for pkg in "${all_pkgs[@]}"; do
        deps=(${pkg_deps["$pkg"]})
        satisfied=true
        for dep in "${deps[@]}"; do
            # If dep is in local set and not yet in install_order, not satisfied
            if [[ -n "${pkg_names[$dep]}" ]] && [[ ! " ${install_order[*]} " =~ " $dep " ]]; then
                satisfied=false
                break
            fi
        done
        
        if $satisfied; then
            install_order+=("$pkg")
            progress=1
        else
            remaining+=("$pkg")
        fi
    done
    
    if [[ $progress -eq 0 ]]; then
        echo "Circular dependency detected or missing dependencies:" >&2
        printf '%s\n' "${remaining[@]}" >&2
        exit 1
    fi
    
    all_pkgs=("${remaining[@]}")
done

# Step 3: Output real paths in install order
for pkg in "${install_order[@]}"; do
    realpath "${pkg_names[$pkg]}"
done
