#!/bin/bash

hostname="${OMARCHY_HOSTNAME:-}"
hostname=${hostname//$'\r'/}

if [[ -z $hostname ]]; then
  exit 0
fi

echo "Setting hostname to $hostname"
sudo hostnamectl set-hostname "$hostname"
