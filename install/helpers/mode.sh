#!/bin/bash

export OMARCHY_INSTALL_MODE="${OMARCHY_INSTALL_MODE:-interactive}"

omarchy_install_mode_is() {
  [[ ${OMARCHY_INSTALL_MODE:-interactive} == "$1" ]]
}

omarchy_install_is_noninteractive() {
  [[ -n ${OMARCHY_NONINTERACTIVE:-} ]] || omarchy_install_mode_is "calamares"
}

export -f omarchy_install_mode_is
export -f omarchy_install_is_noninteractive
