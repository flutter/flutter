#!/bin/bash

set -e

if [[ ! -f $1 ]]; then
  echo "File $1 not found."
  exit -1
fi

GIT_REVISION=${2:-$(git rev-parse HEAD)}
BUILD_ID=${3:-$CIRRUS_BUILD_ID}

if [[ ! -z $GCLOUD_FIREBASE_TESTLAB_KEY ]]; then
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
fi

# Run the test.
# game-loop tests are meant for OpenGL apps.
# This type of test will give the application a handle to a file, and
# we'll write the timeline JSON to that file.
# See https://firebase.google.com/docs/test-lab/android/game-loop
gcloud --project flutter-infra firebase test android run \
  --type game-loop \
  --app $1 \
  --timeout 2m \
  --results-bucket=gs://flutter_firebase_testlab \
  --results-dir=engine_scenario_test/$GIT_REVISION/$BUILD_ID \
  --no-auto-google-login
