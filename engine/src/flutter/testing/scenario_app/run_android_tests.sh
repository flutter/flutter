#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs the Android scenario tests on a connected device.

set -e

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

GRADLE_USER_HOME=$(pwd)/android/gradle-home/.cache

pushd android

set -o pipefail && ./gradlew app:verifyDebugAndroidTestScreenshotTest --gradle-user-home "$GRADLE_USER_HOME"

popd
