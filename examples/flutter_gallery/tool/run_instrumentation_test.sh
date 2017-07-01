#!/bin/sh
set -e

if [ ! -f "./pubspec.yaml" ]; then
  echo "ERROR: current directory must be the root of flutter_gallery package"
  exit 1
fi

cd android
./gradlew connectedAndroidTestProfile -Ptarget=test/live_smoke_test.dart
