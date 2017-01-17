#!/bin/bash

# switch flutter to the latest dev sdk
wget \
  https://storage.googleapis.com/dart-archive/channels/dev/release/latest/sdk/dartsdk-linux-ia32-release.zip
  -O \
  /tmp/dartsdk-linux-ia32-release.zip
unzip /tmp/dartsdk-linux-ia32-release.zip

echo testing against sdk version `cat /tmp/dart-sdk/version`
cat /tmp/dart-sdk/version > bin/internal/dart-sdk.version
./bin/internal/update_dart_sdk.sh

./bin/flutter update-packages

# run tests
dev/bots/docs.sh
