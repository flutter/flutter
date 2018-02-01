#!/bin/bash

set -ex

export PATH="$PWD/bin:$PWD/bin/cache/dart-sdk/bin:$PATH"

if [ "$SHARD" -ne "build_and_deploy_gallery" ]
  dart ./dev/bots/test.dart
else
  if [ "$TRAVIS_OS_NAME" = "linux" ]
    (cd examples/flutter_gallery; flutter build apk --release)
    if [ "$TRAVIS_PULL_REQUEST" = false ] # TODO(xster): add back && [ "$TRAVIS_BRANCH" = "dev" ] after testing
      (cd examples/flutter_gallery/android; bundle exec fastlane deploy_play_store)
    fi
  elif [ "$TRAVIS_OS_NAME" = "osx" ]
    (cd examples/flutter_gallery; flutter build ios --release --no-codesign)
    if [ "$TRAVIS_PULL_REQUEST" = false ] # TODO(xster): add back && [ "$TRAVIS_BRANCH" = "dev" ] after testing
      (cd examples/flutter_gallery/ios; bundle exec fastlane build_and_deploy_testflight)
    fi
  fi
fi

if [ "$TRAVIS_OS_NAME" = "linux" ] && \
   [ "$SHARD" = "docs" ]; then
  # generate the API docs, upload them
  ./dev/bots/docs.sh
fi
