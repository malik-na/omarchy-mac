echo "Fix microphone gain and audio mixing on Asus ROG laptops"

if omarchy-hw-asus-rog; then
  source "$OMARCHY_PATH/install/config/hardware/asus/fix-mic.sh"
  source "$OMARCHY_PATH/install/config/hardware/asus/fix-audio-mixer.sh"
  omarchy-restart-pipewire
fi
