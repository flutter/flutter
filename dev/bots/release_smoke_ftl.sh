#!/bin/bash

set -e

pushd dev/integration_tests/release_smoke_test

../../../bin/flutter build apk \
  --debug \
  --target "test_adapter/hello_world_test.dart" \
  # --target-platform "android-x64"

pushd android

./gradlew assembleAndroidTest

popd

# Runs on firebase test lab.
gcloud firebase test android run \
  --type=instrumentation \
  --app="build/app/outputs/apk/debug/app-debug.apk" \
  --test="build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk" \
  --device model=Pixel2,version=28,locale=en,orientation=portrait \
  --project tong-hello1

popd
