#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs the Android scenario tests on a connected device.

set -e

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

pushd android

set -o pipefail && ./gradlew app:verifyDebugAndroidTestScreenshotTest

popd
