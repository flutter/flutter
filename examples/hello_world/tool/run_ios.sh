#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_ROOT="$(cd "$PROJECT_DIR/../.." && pwd)"
FLUTTER_BIN="$FLUTTER_ROOT/bin/flutter"

find_ios_device() {
  local devices_json
  devices_json="$($FLUTTER_BIN devices --machine 2>/dev/null || echo '[]')"
  DEVICE_JSON="$devices_json" /usr/bin/python3 - <<'PY'
import json
import os

try:
    devices = json.loads(os.environ.get("DEVICE_JSON", "[]"))
except Exception:
    devices = []

for device in devices:
    platform = (device.get("targetPlatform") or "").lower()
    emulator = bool(device.get("emulator"))
    if platform.startswith("ios") and emulator:
        print(device.get("id", ""))
        break
PY
}

IOS_ID="$(find_ios_device)"

if [[ -z "$IOS_ID" ]]; then
  echo "No iOS simulator found. Opening Simulator.app..."
  open -a Simulator || true
  sleep 4
  IOS_ID="$(find_ios_device)"
fi

if [[ -z "$IOS_ID" ]]; then
  echo "No iOS simulator available. Start one in Xcode and try again."
  exit 1
fi

echo "Running on iOS simulator: $IOS_ID"
cd "$PROJECT_DIR"
"$FLUTTER_BIN" run -d "$IOS_ID"
