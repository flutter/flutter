#!/bin/bash

# the bot entry-point - delegate to the correct script

if [ "$BUILD_DOCS" = "true" ]; then
  # generate docs
  dev/bots/docs.sh
else if [ "$DART_SDK_CANARY" = "true" ]; then
  # switch flutter to the latest dev sdk and run tests
  dev/bots/sdk_canary.sh
else
  # run tests
  dev/bots/docs.sh
fi
