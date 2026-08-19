#!/bin/bash

# Apple Silicon (Asahi): the internal keyboard/trackpad HID devices from
# dockchannel-hid first bind to hid-generic, then get destroyed and re-created
# once hid_apple/hid_magicmouse load. That churn reshuffles the input event
# minors while udev, logind, and the compositor are starting; on unlucky boots
# logind's TakeDevice fails for the trackpad node (libseat "Couldn't open
# device") and libinput never retries, leaving the trackpad dead for the whole
# session. Loading the drivers from the initramfs makes the devices bind
# correctly on first registration, so the churn never happens.
# See docs/apple-silicon-trackpad.md.
if [[ $(uname -m) == "aarch64" ]] && grep -qi apple /proc/device-tree/compatible 2>/dev/null; then
  echo "Detected Apple Silicon Mac: early-loading Apple HID modules"
  sudo mkdir -p /etc/mkinitcpio.conf.d
  echo "MODULES+=(hid_apple hid_magicmouse)" | \
    sudo tee /etc/mkinitcpio.conf.d/apple_hid_modules.conf >/dev/null
fi
