#!/bin/bash

set -e

function script_location() {
  local script_location="${BASH_SOURCE[0]}"
  # Resolve symlinks
  while [[ -h "$script_location" ]]; do
    DIR="$(cd -P "$(dirname "$script_location")" >/dev/null && pwd)"
    script_location="$(readlink "$script_location")"
    [[ "$script_location" != /* ]] && script_location="$DIR/$script_location"
  done
  echo "$(cd -P "$(dirname "$script_location")" >/dev/null && pwd)"
}

# So that users can run this script locally from any directory and it will work as
# expected.
SCRIPT_LOCATION="$(script_location)"
FLUTTER_ROOT="$(dirname "$(dirname "$SCRIPT_LOCATION")")"

export PATH="$FLUTTER_ROOT/bin:$FLUTTER_ROOT/bin/cache/dart-sdk/bin:$PATH"

set -x

cd "$FLUTTER_ROOT"

if [[ "$SHARD" = "deploy_gallery" ]]; then
  version="$(<version)"
  if [[ "$OS" == "linux" ]]; then
    echo "Building Flutter Gallery $version for Android..."

    # ANDROID_SDK_ROOT must be set in the env.
    (
      cd examples/flutter_gallery
      flutter build apk --release -t lib/main_publish.dart
    )
    echo "Android Flutter Gallery built"
    if [[ -z "$CIRRUS_PR" && "$CIRRUS_BRANCH" == "dev" && "$version" != *"pre"* ]]; then
      echo "Deploying Flutter Gallery $version to Play Store..."
      set +x # Don't echo back the below.
      if [ -n "$ANDROID_GALLERY_UPLOAD_KEY" ]; then
        echo "$ANDROID_GALLERY_UPLOAD_KEY" | base64 --decode > /root/.android/debug.keystore
      fi
      set -x
      (
        cd examples/flutter_gallery/android
        fastlane deploy_play_store
      )
    else
      echo "Not deployed: Flutter Gallery is only deployed to the Play Store on merged and tagged dev branch commits"
    fi
  elif [[ "$OS" == "darwin" ]]; then
    echo "Building Flutter Gallery $version for iOS..."
    (
      cd examples/flutter_gallery
      flutter build ios --release --no-codesign -t lib/main_publish.dart
    )
    echo "iOS Flutter Gallery built"
    if [[ -z "$CIRRUS_PR" ]]; then
      if [[ "$CIRRUS_BRANCH" == "dev" && "$version" != *"pre"* ]]; then
        echo "Archiving with distribution profile and deploying to TestFlight..."
        (
          cd examples/flutter_gallery/ios
          fastlane build_and_deploy_testflight upload:true
        )
      else
        echo "Archiving with distribution profile..."
        (
          cd examples/flutter_gallery/ios
          fastlane build_and_deploy_testflight
        )
        echo "Archive is only deployed to TestFlight on tagged dev branch commits"
      fi
    else
      echo "Not deployed: Flutter Gallery is only deployed to TestFlight on merged and tagged dev branch commits"
    fi
  fi
else
  echo "Doing nothing: not on the 'deploy_gallery' SHARD."
fi
