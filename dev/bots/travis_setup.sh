#!/bin/bash
set -e

echo $KEY_FILE | base64 --decode > ../gcloud_key_file.json

set -x

if [ -n "$TRAVIS" ]; then
  export CLOUDSDK_CORE_DISABLE_PROMPTS=1
  echo "Installing Google Cloud SDK..."
  curl https://sdk.cloud.google.com | bash > /dev/null
  echo "Google Cloud SDK installation completed."
fi

# disable analytics on the bots and download Flutter dependencies
./bin/flutter config --no-analytics

# run pub get in all the repo packages
./bin/flutter update-packages
