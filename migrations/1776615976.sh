echo "Install missing Intel VPL drivers (libvpl, vpl-gpu-rt) on systems with Intel GPUs"

if omarchy-hw-intel; then
  bash "$OMARCHY_PATH/install/config/hardware/intel/video-acceleration.sh"
fi
