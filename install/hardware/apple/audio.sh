#!/bin/bash
# Sound on Apple Silicon needs two things this install would otherwise never
# get, for two different reasons.
#
# PipeWire's PulseAudio server: install/omarchy-other.packages lists
# pipewire-pulse and says why it is not in the base set -- "Utilized by ISO
# builder to ensure package availability in the ISO". x86 machines get it from
# the ISO. A Mac has no ISO, and wireplumber pulls in pipewire but not
# pipewire-pulse, so the machine ends up with a running audio server that
# nothing can talk to: pactl says "Connection refused", and every Omarchy audio
# command exits 1 -- the volume and mute keys do nothing while brightness works
# fine, because brightness never touches PulseAudio.
#
# Then the Apple parts: asahi-audio carries the UCM profiles and the DSP filter
# chain that makes a speaker sink exist at all, and speakersafetyd is what
# allows the speakers to play. Without the daemon the kernel keeps them muted,
# on purpose -- these drivers can be damaged by what the hardware will happily
# ask them to do.

[[ $(uname -m) == "aarch64" ]] || return 0
[[ -d /proc/device-tree/chosen/asahi ]] || [[ -f /proc/device-tree/compatible ]] || return 0

echo "Installing the Apple Silicon audio stack"
omarchy-pkg-add pipewire-pulse pipewire-alsa asahi-audio speakersafetyd ||
  echo "Warning: some audio packages could not be installed; sound may not work."

# The daemon has to be running before the speakers will produce anything.
sudo systemctl enable --now speakersafetyd >/dev/null 2>&1 ||
  echo "Warning: speakersafetyd did not start; the speakers stay muted."

# pipewire-pulse is socket-activated per user, so enabling it system-wide is not
# the job; the user units are enabled at first run.
