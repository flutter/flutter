#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

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

version="$(<version)"
if [[ "$OS" == "linux" ]]; then
  echo "Building Flutter Gallery $version for Android..."
  export BUNDLE_GEMFILE="$FLUTTER_ROOT/dev/ci/docker_linux/Gemfile"
  # ANDROID_SDK_ROOT must be set in the env.
  (
    cd dev/integration_tests/flutter_gallery
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
      cd dev/integration_tests/flutter_gallery/android
      bundle exec fastlane deploy_play_store
    )
  else
    echo "(Not deploying; Flutter Gallery is only deployed to Play store for tagged dev branch commits.)"
  fi
elif [[ "$OS" == "darwin" ]]; then
  echo "Building Flutter Gallery $version for iOS..."
  export BUNDLE_GEMFILE="$FLUTTER_ROOT/dev/ci/mac/Gemfile"
  (
    cd dev/integration_tests/flutter_gallery
    flutter build ios --release --no-codesign -t lib/main_publish.dart

    # flutter build ios will run CocoaPods script. Check generated locations.
    if [[ ! -d "ios/Pods" ]]; then
      echo "Error: pod install failed to setup plugins"
      exit 1
    fi

    if [[ ! -d "ios/.symlinks/plugins" ]]; then
      echo "Error: pod install failed to setup plugin symlinks"
      exit 1
    fi

    if [[ -d "ios/.symlinks/flutter" ]]; then
      echo "Error: pod install created flutter symlink"
      exit 1
    fi

    if [[ ! -d "build/ios/iphoneos/Flutter Gallery.app/Frameworks/App.framework/flutter_assets" ]]; then
      echo "Error: flutter_assets not assembled"
      exit 1
    fi

    if [[
      -d "build/ios/iphoneos/Flutter Gallery.app/Frameworks/App.framework/flutter_assets/isolate_snapshot_data" ||
      -d "build/ios/iphoneos/Flutter Gallery.app/Frameworks/App.framework/flutter_assets/kernel_blob.bin" ||
      -d "build/ios/iphoneos/Flutter Gallery.app/Frameworks/App.framework/flutter_assets/vm_snapshot_data"
     ]]; then
      echo "Error: compiled debug version of app with --release flag"
      exit 1
    fi
  )
  echo "iOS Flutter Gallery built"
  if [[ -z "$CIRRUS_PR" ]]; then
    if [[ "$CIRRUS_BRANCH" == "dev" && "$version" != *"pre"* ]]; then
      echo "Archiving with distribution profile and deploying to TestFlight..."
      (
        cd dev/integration_tests/flutter_gallery/ios
        export DELIVER_ITMSTRANSPORTER_ADDITIONAL_UPLOAD_PARAMETERS="-t DAV"
        bundle exec fastlane build_and_deploy_testflight upload:true
      )
    else
      # On iOS the signing can break as well, so we verify this regularly (not just
      # on tagged dev branch commits). We can only do this post-merge, though, because
      # the secrets aren't available on PRs.
      echo "Testing archiving with distribution profile..."
      (
        cd dev/integration_tests/flutter_gallery/ios
        # Cirrus Mac VMs come with an old version of fastlane which was causing
        # dependency issues (https://github.com/flutter/flutter/issues/43435),
        # so explicitly use the version specified in $BUNDLE_GEMFILE.
        bundle exec fastlane build_and_deploy_testflight
      )
      echo "(Not deploying; Flutter Gallery is only deployed to TestFlight for tagged dev branch commits.)"
    fi
  else
    echo "(Not archiving or deploying; Flutter Gallery archiving is only tested post-commit.)"
  fi
else
  echo "Unknown OS: $OS"
  echo "Aborted."
  exit 1
fi
