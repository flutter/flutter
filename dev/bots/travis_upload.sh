#!/bin/bash

set -ex

export PATH="$PWD/bin:$PWD/bin/cache/dart-sdk/bin:$PATH"

if [ "$TRAVIS_OS_NAME" = "linux" ] && \
   [ "$SHARD" = "docs" ]; then
  # generate the API docs, upload them
  ./dev/bots/docs.sh
fi
