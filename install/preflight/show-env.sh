#!/bin/bash
# Show installation environment variables
log_install_env() {
  if omarchy_install_is_noninteractive; then
    echo "[INFO] $1"
  else
    gum log --level info "$1"
  fi
}

log_install_env "Installation Environment:"

env | grep -E "^(OMARCHY_CHROOT_INSTALL|OMARCHY_INSTALL_MODE|OMARCHY_ONLINE_INSTALL|OMARCHY_USER_NAME|OMARCHY_USER_EMAIL|OMARCHY_TIMEZONE|OMARCHY_HOSTNAME|OMARCHY_OPTIONAL_PACKAGES|USER|HOME|OMARCHY_REPO|OMARCHY_REF|OMARCHY_PATH)=" | sort | while IFS= read -r var; do
  log_install_env "  $var"
done
