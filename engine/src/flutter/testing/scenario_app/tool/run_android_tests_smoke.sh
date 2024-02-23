#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is a debugging script that runs a single Android E2E test on a connected
# device or emulator, and reports the exit code. It was largely created to debug
# why `./testing/scenario_app/run_android_tests.sh` did or did not report
# failures correctly.

ADB="../third_party/android_tools/sdk/platform-tools/adb"
OUT_DIR="../out/android_debug_unopt_arm64"
SMOKE_TEST="dev.flutter.scenarios.EngineLaunchE2ETest"

# Optionally skip installation if -s is passed.
if [ "$1" != "-s" ]; then
  # Install the app and test APKs.
  echo "Installing app and test APKs..."
  $ADB install -r $OUT_DIR/scenario_app/app/outputs/apk/debug/app-debug.apk
  $ADB install -r $OUT_DIR/scenario_app/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
fi

# Configure the device for testing.
echo "Configuring device for testing..."
$ADB shell settings put secure immersive_mode_confirmations confirmed

# Reverse port 3000 to the device.
echo "Reversing port 3000 to the device..."
$ADB reverse tcp:3000 tcp:3000

# Run the test.
echo "Running test..."
$ADB shell am instrument -w -r -e class $SMOKE_TEST dev.flutter.scenarios.test/dev.flutter.TestRunner

# Reverse port 3000 to the device.
echo "Reversing port 3000 to the device..."
$ADB reverse --remove tcp:3000
