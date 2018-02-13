#!/bin/bash

set -ex

export PATH="$PWD/bin:$PWD/bin/cache/dart-sdk/bin:$PATH"

if [ "$SHARD" = "build_and_deploy_gallery" ]; then
  echo "Building and deploying Flutter Gallery"
  if [ "$TRAVIS_OS_NAME" = "linux" ]; then
    echo "Building Flutter Gallery for Android..."
    export ANDROID_HOME=`pwd`/android-sdk
    (cd examples/flutter_gallery; flutter build apk --release)
    echo "Android Flutter Gallery built"
    if [[ "$TRAVIS_PULL_REQUEST" == "false" && ("$TRAVIS_BRANCH" == "dev" || "$TRAVIS_BRANCH" == "beta") ]]; then
      echo "Deploying to Play Store..."
      (cd examples/flutter_gallery/android; bundle install && bundle exec fastlane deploy_play_store)
    else
      echo "Flutter Gallery is only deployed to the Play Store on merged dev branch commits"
    fi
  elif [ "$TRAVIS_OS_NAME" = "osx" ]; then
    echo "Building Flutter Gallery for iOS..."
    (cd examples/flutter_gallery; flutter build ios --release --no-codesign)
    echo "iOS Flutter Gallery built"
    if [[ "$TRAVIS_PULL_REQUEST" == "false" && ("$TRAVIS_BRANCH" == "dev" || "$TRAVIS_BRANCH" == "beta") ]]; then
      echo "Re-building with distribution profile and deploying to TestFlight..."
      (cd examples/flutter_gallery/ios; bundle install && bundle exec fastlane build_and_deploy_testflight)
    else
      echo "Flutter Gallery is only deployed to the TestFlight on merged dev branch commits"
    fi
  fi
elif [ "$SHARD" = "docs" ]; then
  if [ "$TRAVIS_OS_NAME" = "linux" ]; then
    # Generate the API docs, upload them
    ./dev/bots/docs.sh
  fi
else
  dart ./dev/bots/test.dart
fi
