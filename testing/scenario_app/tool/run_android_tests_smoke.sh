#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is a debugging script that runs a single Android E2E test on a connected
# device or emulator, and reports the exit code. It was largely created to debug
# why `./testing/scenario_app/run_android_tests.sh` did or did not report
# failures correctly.

# Run this command and print out the exit code.
../third_party/dart/tools/sdks/dart-sdk/bin/dart ./testing/scenario_app/bin/android_integration_tests.dart \
  --adb="../third_party/android_tools/sdk/platform-tools/adb" \
  --out-dir="../out/android_debug_unopt_arm64" \
  --smoke-test

echo "Exit code: $?"
echo "Done"
