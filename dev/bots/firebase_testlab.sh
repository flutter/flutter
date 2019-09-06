#!/bin/bash

set -e

GIT_REVISION=$(git rev-parse HEAD)

pushd dev/integration_tests/release_smoke_test

../../../bin/flutter build appbundle --target-platform android-arm,android-arm64

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

# Firebase Test Lab tests are currently known to be failing with
# "Firebase Test Lab infrastructure failure: Error during preprocessing"
# Remove "|| exit 0" once the failures are resolved
# https://github.com/flutter/flutter/issues/36501

# Run the test.
gcloud firebase test android run --type robo \
  --app build/app/outputs/bundle/release/app.aab \
  --timeout 2m \
  --results-bucket=gs://flutter_firebase_testlab \
  --results-dir=release_smoke_test/$GIT_REVISION/$CIRRUS_BUILD_ID || exit 0

# Check logcat for "E/flutter" - if it's there, something's wrong.
gsutil cp gs://flutter_firebase_testlab/release_smoke_test/$GIT_REVISION/$CIRRUS_BUILD_ID/walleye-26-en-portrait/logcat /tmp/logcat
! grep "E/flutter" /tmp/logcat || false
grep "I/flutter" /tmp/logcat

popd
