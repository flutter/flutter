#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# The tests to run on Firebase Test Lab.
# Currently, the test consists on building an Android App Bundle and ensuring
# that the app doesn't crash upon startup.
#
# When adding a test, ensure that there's at least a `print()` statement under lib/*.dart.
#
# The first and only parameter should be the path to an integration test.

# The devices where the tests are run.
#
# To get the full list of devices available, run:
#     gcloud firebase test android models list
devices=(
  # Pixel 3
  "model=blueline,version=28"

  # Pixel 4
  "model=flame,version=29"

  # Moto Z XT1650
  "model=griffin,version=24"
)

set -e

GIT_REVISION=$(git rev-parse HEAD)

DEVICE_FLAG=""
for device in ${devices[*]}; do
  DEVICE_FLAG+="--device $device "
done

# New contributors will not have permissions to run this test - they won't be
# able to access the service account information. We should just mark the test
# as passed - it will run fine on post submit, where it will still catch
# failures.
# We can also still make sure that building a release app bundle still works.
if [[ $GCLOUD_FIREBASE_TESTLAB_KEY == ENCRYPTED* ]]; then
  echo "This user does not have permission to run this test."
  exit 0
fi

echo $GCLOUD_FIREBASE_TESTLAB_KEY > ${HOME}/gcloud-service-key.json
gcloud auth activate-service-account --key-file=${HOME}/gcloud-service-key.json
gcloud --quiet config set project flutter-infra

function test_app_bundle() {
  pushd "$@"
  ../../../bin/flutter build appbundle --target-platform android-arm,android-arm64

  aab="build/app/outputs/bundle/release/app-release.aab"

  # If the app bundle doesn't exist, then exit with code 1.
  if [ ! -f "$aab" ]; then
    exit 1
  fi

  # Run the test.
  gcloud firebase test android run \
    --type robo \
    --app "$aab" \
    --timeout 2m \
    --results-bucket=gs://flutter_firebase_testlab \
    --results-dir="$@"/"$GIT_REVISION"/"$CIRRUS_BUILD_ID" \
    $DEVICE_FLAG

  rm -f /tmp/logcat
  gsutil cat gs://flutter_firebase_testlab/"$@"/"$GIT_REVISION"/"$CIRRUS_BUILD_ID"/*/logcat > /tmp/logcat
  # Check logcat for "E/flutter" - if it's there, something's wrong.
  ! grep "E/flutter" /tmp/logcat || false
  # Check logcat for "I/flutter" - This is in the log if there's a print statement under lib/*.dart.
  grep "I/flutter" /tmp/logcat
  popd
}

test_app_bundle "$1"
