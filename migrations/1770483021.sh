echo "Install Framework 16 keyboard RGB support"

if omarchy-hw-framework16; then
  source $OMARCHY_PATH/install/packaging/framework16.sh
  source $OMARCHY_PATH/install/config/hardware/framework/qmk-hid.sh
fi
