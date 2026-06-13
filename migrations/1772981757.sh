echo "Install Intel GPU hardware acceleration drivers if missing"

if omarchy-hw-intel && lspci | grep -iE 'vga|3d|display' | grep -qi 'intel'; then
  source "$OMARCHY_PATH/install/config/hardware/intel/video-acceleration.sh"
fi
