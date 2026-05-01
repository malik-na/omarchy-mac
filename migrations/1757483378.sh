echo "6Ghz Wi-Fi + Intel graphics acceleration for existing installations"

bash "$OMARCHY_PATH/install/config/hardware/set-wireless-regdom.sh"
if omarchy-hw-intel; then
  bash "$OMARCHY_PATH/install/config/hardware/intel/video-acceleration.sh"
fi
