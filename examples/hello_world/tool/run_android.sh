#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_ROOT="$(cd "$PROJECT_DIR/../.." && pwd)"
FLUTTER_BIN="$FLUTTER_ROOT/bin/flutter"

find_android_device() {
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
    if platform.startswith("android"):
        print(device.get("id", ""))
        break
PY
}

ANDROID_ID="$(find_android_device)"

if [[ -z "$ANDROID_ID" ]]; then
  echo "No Android device/emulator found."
  echo "Start one in Android Studio Device Manager and try again."
  exit 1
fi

echo "Running on Android device/emulator: $ANDROID_ID"
cd "$PROJECT_DIR"
"$FLUTTER_BIN" run -d "$ANDROID_ID"
