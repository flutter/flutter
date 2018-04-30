#!/bin/bash

set -ex

export PATH="$PWD/bin:$PWD/bin/cache/dart-sdk/bin:$PATH"

if [ "$SHARD" = "build_and_deploy_gallery" ]; then
  version=$(<version)
  echo "Building and deploying Flutter Gallery $version"
  if [ "$TRAVIS_OS_NAME" = "linux" ]; then
    echo "Building Flutter Gallery for Android..."
    export ANDROID_HOME=`pwd`/android-sdk
    (
      cd examples/flutter_gallery
      flutter build apk --release -t lib/main_publish.dart
    )
    echo "Android Flutter Gallery built"
    if [[ "$TRAVIS_PULL_REQUEST" == "false" && "$TRAVIS_BRANCH" == "dev" && $version != *"pre"* ]]; then
      echo "Deploying to Play Store..."
      (
        cd examples/flutter_gallery/android
        bundle install
        bundle exec fastlane deploy_play_store
      )
    else
      echo "Flutter Gallery is only deployed to the Play Store on merged and tagged dev branch commits"
    fi
  elif [ "$TRAVIS_OS_NAME" = "osx" ]; then
    echo "Building Flutter Gallery for iOS..."
    (
      cd examples/flutter_gallery
      flutter build ios --release --no-codesign -t lib/main_publish.dart
    )
    echo "iOS Flutter Gallery built"
    if [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
      if [[ "$TRAVIS_BRANCH" == "dev" && $version != *"pre"* ]]; then
        echo "Archiving with distribution profile and deploying to TestFlight..."
        (
          cd examples/flutter_gallery/ios
          bundle install
          bundle exec fastlane build_and_deploy_testflight upload:true
        )
      else
        echo "Archiving with distribution profile..."
        (
          cd examples/flutter_gallery/ios
          bundle install
          bundle exec fastlane build_and_deploy_testflight
        )
        echo "Archive is only deployed to TestFlight on tagged dev branch commits"
      fi
    else
      echo "Flutter Gallery is only deployed to the TestFlight on merged and tagged dev branch commits"
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
