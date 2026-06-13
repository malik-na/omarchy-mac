echo "Fix audio input on AMD Framework laptops"

if omarchy-hw-framework16; then
  source $OMARCHY_PATH/install/config/hardware/framework/fix-f13-amd-audio-input.sh || true
fi
