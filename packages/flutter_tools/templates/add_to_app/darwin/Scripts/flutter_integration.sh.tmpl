#!/bin/bash

# Generated file. Do not edit.

# This script is intended to be used as a "Run Script" build phase in an iOS or macOS native app.
# It runs a Swift package tool that ensures the correct build mode is being used for Flutter
# artifacts and re-builds the Flutter application if possible.

set -euo pipefail

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

FLUTTER_NATIVE_INTEGRATION_PACKAGE_PATH="$FLUTTER_SWIFT_PACKAGE_OUTPUT/FlutterNativeIntegration"
FLUTTER_NATIVE_TOOLS_PACKAGE_PATH="$FLUTTER_NATIVE_INTEGRATION_PACKAGE_PATH/FlutterNativeTools"
export FLUTTER_NATIVE_INTEGRATION_PACKAGE_PATH

FLUTTER_SCRIPT_ACTION="$@"
if [[ "$FLUTTER_SCRIPT_ACTION" != "assemble" ]] && [[ "$FLUTTER_SCRIPT_ACTION" != "prebuild" ]]; then
  echo "error: Invalid argument: $FLUTTER_SCRIPT_ACTION. Allowed arguments include: prebuild and assemble"
  exit 1
fi

FLUTTER_TOOL="flutter-$FLUTTER_SCRIPT_ACTION-tool"
FLUTTER_TOOL_BUILD_PATH=".build/$FLUTTER_SCRIPT_ACTION"
FLUTTER_TOOL_BUILD_MODE="release"


buildTool() {
  cd "$FLUTTER_NATIVE_TOOLS_PACKAGE_PATH" || exit 1
  xcrun --sdk macosx swift package clean --build-path "$FLUTTER_TOOL_BUILD_PATH"
  xcrun --sdk macosx swift build --product $FLUTTER_TOOL --build-path "$FLUTTER_TOOL_BUILD_PATH" -c $FLUTTER_TOOL_BUILD_MODE --disable-sandbox
}

# Use prebuilt tool if possible, otherwise re-build it for next time
PREBUILT_FLUTTER_TOOL="$FLUTTER_NATIVE_TOOLS_PACKAGE_PATH/$FLUTTER_TOOL_BUILD_PATH/$FLUTTER_TOOL_BUILD_MODE/$FLUTTER_TOOL"
if [[ -z "${REBUILD_FLUTTER_TOOL+set}" ]] || [[ "$REBUILD_FLUTTER_TOOL" != "YES" ]]; then
  PREBUILT_FLUTTER_TOOL_SCAN=$(gktool scan "$PREBUILT_FLUTTER_TOOL") || REBUILD_FLUTTER_TOOL="YES"
  if [[ "$PREBUILT_FLUTTER_TOOL_SCAN" != *"Scan completed and software is allowed by system policy."* ]]; then
    echo "Gatekeeper check failed: $PREBUILT_FLUTTER_TOOL_SCAN"
    REBUILD_FLUTTER_TOOL="YES"
  fi
fi
if [[ -n "${REBUILD_FLUTTER_TOOL+set}" ]] && [[ "$REBUILD_FLUTTER_TOOL" == "YES" ]]; then
  buildTool
fi

FLUTTER_TOOL_STATUS=0
FLUTTER_TOOL_OUTPUT=$("$PREBUILT_FLUTTER_TOOL" 2>&1) || FLUTTER_TOOL_STATUS=$?
if [[ $FLUTTER_TOOL_STATUS -ne 0 ]] && [[ "$FLUTTER_TOOL_OUTPUT" == *"Operation not permitted"* ]]; then
  buildTool
  "$PREBUILT_FLUTTER_TOOL"
else
  echo "$FLUTTER_TOOL_OUTPUT" & exit $FLUTTER_TOOL_STATUS
fi
