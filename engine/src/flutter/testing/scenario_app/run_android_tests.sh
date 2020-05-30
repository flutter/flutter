#!/bin/sh
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs the Android scenario tests on a connected device.

set -e

FLUTTER_ENGINE=android_profile_unopt_arm64

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

pushd android

set -o pipefail && ./gradlew app:verifyDebugAndroidTestScreenshotTest

popd
