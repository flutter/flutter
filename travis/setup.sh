#!/bin/bash
set -e

if [ $TRAVIS_PULL_REQUEST = "false" ]; then
  echo $KEY_FILE | base64 --decode > gcloud_key_file.json
fi

set -x

dart dev/update_packages.dart
(cd packages/unit; ../../bin/flutter cache populate)

if [ $TRAVIS_PULL_REQUEST = "false" ]; then
  export CLOUDSDK_CORE_DISABLE_PROMPTS=1
  curl https://sdk.cloud.google.com | bash
fi
