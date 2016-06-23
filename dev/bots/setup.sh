#!/bin/bash
set -e

echo $KEY_FILE | base64 --decode > ../gcloud_key_file.json

set -x

export CLOUDSDK_CORE_DISABLE_PROMPTS=1
curl https://sdk.cloud.google.com | bash

# disable analytics on the bots and download Flutter dependencies
./bin/flutter config --no-analytics

# run pub get in all the repo packages
./bin/flutter update-packages
