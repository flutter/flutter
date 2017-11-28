#!/bin/sh
set -e

if [ ! -f "./pubspec.yaml" ]; then
  echo "ERROR: current directory must be the root of flutter_gallery package"
  exit 1
fi

cd android

# Currently there's no non-hacky way to pass a device ID to gradlew, but it's
# OK as in the devicelab we have one device per host.
#
# See also: https://goo.gl/oe5aUW
./gradlew connectedAndroidTest -Ptarget=test/live_smoketest.dart
