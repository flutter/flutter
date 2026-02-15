#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

if [ ! -f "./pubspec.yaml" ]; then
  echo "ERROR: current directory must be the root of flutter_gallery package"
  exit 1
fi

cd android

# Currently there's no non-hacky way to pass a device ID to gradlew, but it's
# OK as in the devicelab we have one device per host.
#
# See also: https://stackoverflow.com/q/23960667/
./gradlew connectedAndroidTest -Ptarget=test/live_smoketest.dart
