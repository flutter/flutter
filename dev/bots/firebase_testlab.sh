#!/bin/bash

set -e

GIT_REVISION=$(git rev-parse HEAD)

pushd examples/hello_world

../../bin/flutter build apk --release --target-platform android-arm --split-per-abi

echo $GCLOUD_FIREBASE_TESTLAB_KEY > ${HOME}/gcloud-service-key.json
gcloud auth activate-service-account --key-file=${HOME}/gcloud-service-key.json
gcloud --quiet config set project flutter-infra

# Run the test.
gcloud firebase test android run --type robo \
  --app build/app/outputs/apk/release/app-armeabi-v7a-release.apk \
  --timeout 2m \
  --results-bucket=gs://flutter_firebase_testlab \
  --results-dir=release_smoketests/hello_world/$GIT_REVISION

# Check logcat for "E/flutter" - if it's there, something's wrong.
! gsutil cat gs://flutter_firebase_testlab/release_smoketests/hello_world/$GIT_REVISION/walleye-26-en-portrait/logcat | grep "E/flutter" || false

popd
