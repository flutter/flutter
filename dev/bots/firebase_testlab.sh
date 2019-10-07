#!/bin/bash

# The tests to run on Firebase Test Lab.
# Currently, the test consists on building an Android App Bundle and ensuring
# that the app doesn't crash upon startup.
tests=(
  "dev/integration_tests/release_smoke_test"
  "dev/integration_tests/abstract_method_smoke_test"
)

set -e

GIT_REVISION=$(git rev-parse HEAD)

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

  # Firebase Test Lab tests are currently known to be failing with
  # "Firebase Test Lab infrastructure failure: Error during preprocessing"
  # Remove "|| exit 0" once the failures are resolved
  # https://github.com/flutter/flutter/issues/36501

  # Run the test.
  gcloud firebase test android run --type robo \
    --app build/app/outputs/bundle/release/app.aab \
    --timeout 2m \
    --results-bucket=gs://flutter_firebase_testlab \
    --results-dir="$@"/"$GIT_REVISION"/"$CIRRUS_BUILD_ID" || exit 0

    # Check logcat for "E/flutter" - if it's there, something's wrong.
    gsutil cp gs://flutter_firebase_testlab/"$@"/"$GIT_REVISION"/"$CIRRUS_BUILD_ID"/walleye-26-en-portrait/logcat /tmp/logcat
    ! grep "E/flutter" /tmp/logcat || false
    grep "I/flutter" /tmp/logcat
    popd
}

for test in ${tests[*]}; do
  test_app_bundle $test
done
