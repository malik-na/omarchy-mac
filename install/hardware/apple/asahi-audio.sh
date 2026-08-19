# Apple Silicon speakers need Asahi's protected DSP graph and safety daemon.
# The PulseAudio and ALSA compatibility packages both depend on pipewire-audio,
# which supplies PipeWire's ALSA SPA plugin and completes the audio stack.
compatible="${OMARCHY_APPLE_COMPATIBLE:-/proc/device-tree/compatible}"
OMARCHY_ASAHI_AUDIO_PACKAGES_CHANGED=0

if [[ $(uname -m) == "aarch64" ]] &&
  [[ -f $compatible ]] &&
  grep -Faiq 'apple,' "$compatible"; then
  if omarchy-pkg-missing pipewire-pulse pipewire-alsa asahi-audio; then
    echo "Installing the protected Asahi audio stack"
    omarchy-pkg-add pipewire-pulse pipewire-alsa asahi-audio
    if ! omarchy-pkg-present pipewire-pulse pipewire-alsa asahi-audio; then
      echo "Error: protected Asahi audio stack is incomplete after package installation" >&2
      return 1
    fi
    OMARCHY_ASAHI_AUDIO_PACKAGES_CHANGED=1
  fi
fi
