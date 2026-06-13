#!/bin/bash

set -euo pipefail

OMARCHY_PATH="${OMARCHY_PATH:-$(pwd)}"
TEST_DIR=$(mktemp -d)
FAKE_BIN="$TEST_DIR/bin"
FAKE_POWER_SUPPLY="$TEST_DIR/power_supply"
NOTIFY_LOG="$TEST_DIR/notify.log"
FLAG_FILE="$TEST_DIR/notified.flag"

mkdir -p "$FAKE_BIN" "$FAKE_POWER_SUPPLY/macsmc-battery"

cleanup() {
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT

cat > "$FAKE_BIN/omarchy-battery-remaining" <<'EOF'
#!/bin/bash
printf '%s\n' "${TEST_BATTERY_LEVEL:-100}"
EOF

cat > "$FAKE_BIN/upower" <<'EOF'
#!/bin/bash
if [[ ${1:-} == "-e" ]]; then
  printf '%s\n' "/org/freedesktop/UPower/devices/battery_macsmc_battery"
  exit 0
fi

if [[ ${1:-} == "-i" ]]; then
  cat <<INFO
  native-path:          macsmc-battery
  state:                ${TEST_BATTERY_STATE:-charging}
INFO
  exit 0
fi

exit 1
EOF

cat > "$FAKE_BIN/notify-send" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "$TEST_NOTIFY_LOG"
EOF

chmod +x "$FAKE_BIN/omarchy-battery-remaining" "$FAKE_BIN/upower" "$FAKE_BIN/notify-send"

printf 'Battery\n' > "$FAKE_POWER_SUPPLY/macsmc-battery/type"
printf '1\n' > "$FAKE_POWER_SUPPLY/macsmc-battery/present"

export PATH="$FAKE_BIN:$PATH"
export TEST_NOTIFY_LOG="$NOTIFY_LOG"
export OMARCHY_BATTERY_NOTIFICATION_FLAG="$FLAG_FILE"
export OMARCHY_POWER_SUPPLY_PATH="$FAKE_POWER_SUPPLY"

run_monitor() {
  "$OMARCHY_PATH/bin/omarchy-battery-monitor"
}

assert_notifications() {
  local expected=$1
  local actual=0

  if [[ -f $NOTIFY_LOG ]]; then
    actual=$(wc -l < "$NOTIFY_LOG")
  fi

  if (( actual != expected )); then
    printf 'Expected %s notifications, got %s\n' "$expected" "$actual"
    exit 1
  fi
}

echo "=== Simulate low battery notification ==="
"$OMARCHY_PATH/bin/omarchy-battery-present"
TEST_BATTERY_LEVEL=9 TEST_BATTERY_STATE=discharging run_monitor
assert_notifications 1
[[ -f $FLAG_FILE ]]
echo "ok: generic battery detection sends one notification"

echo "=== Repeat low battery simulation ==="
TEST_BATTERY_LEVEL=8 TEST_BATTERY_STATE=discharging run_monitor
assert_notifications 1
echo "ok: repeat low battery does not spam notifications"

echo "=== Simulate charging reset ==="
TEST_BATTERY_LEVEL=8 TEST_BATTERY_STATE=charging run_monitor
[[ ! -f $FLAG_FILE ]]
assert_notifications 1
echo "ok: charging clears notification flag"

echo "=== Simulate low battery after reset ==="
TEST_BATTERY_LEVEL=7 TEST_BATTERY_STATE=discharging run_monitor
assert_notifications 2
echo "ok: notification is sent again after reset"

echo "=== Battery monitor tests passed ==="
