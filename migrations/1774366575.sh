echo "Install Intel Low Power Mode for Intel CPUs"

if omarchy-hw-intel; then
  source "$OMARCHY_PATH/install/config/hardware/intel/lpmd.sh"
fi
