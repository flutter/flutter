#!/bin/bash

# the bot entry-point - delegate to the correct script

if [ "$BUILD_DOCS" = "true" ]; then
  # generate docs
  dev/bots/docs.sh
elif [ "$DART_SDK_CANARY" = "true" ]; then
  # switch flutter to the latest dev sdk and run tests
  dev/bots/sdk_canary.sh
else
  # run tests
  dev/bots/test.sh

  if [ -n "$COVERAGE_FLAG" ]; then
    GSUTIL=$HOME/google-cloud-sdk/bin/gsutil
    GCLOUD=$HOME/google-cloud-sdk/bin/gcloud

    $GCLOUD auth activate-service-account --key-file ../gcloud_key_file.json
    STORAGE_URL=gs://flutter_infra/flutter/coverage/lcov.info
    $GSUTIL cp packages/flutter/coverage/lcov.info $STORAGE_URL
  fi

  (cd packages/flutter && coveralls-lcov coverage/lcov.info)
fi
