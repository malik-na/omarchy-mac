#!/bin/bash

if pgrep -f "\b(wf-recorder|gpu-screen-recorder)\b" >/dev/null; then
  echo '{"text": "󰻂", "tooltip": "Stop recording", "class": "active"}'
else
  echo '{"text": ""}'
fi
