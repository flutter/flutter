#!/bin/bash
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `update_dart_sdk.ps1` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# -------------------------------------------------------------------------- #

set -e

FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

DART_SDK_PATH="$FLUTTER_ROOT/bin/cache/dart-sdk"
DART_SDK_STAMP_PATH="$FLUTTER_ROOT/bin/cache/dart-sdk.stamp"
DART_SDK_VERSION=`cat "$FLUTTER_ROOT/bin/internal/dart-sdk.version"`

if [ ! -f "$DART_SDK_STAMP_PATH" ] || [ "$DART_SDK_VERSION" != `cat "$DART_SDK_STAMP_PATH"` ]; then
  echo "Downloading Dart SDK $DART_SDK_VERSION..."

  case "$(uname -s)" in
    Darwin)
      DART_ZIP_NAME="dartsdk-macos-x64-release.zip"
      ;;
    Linux)
      DART_ZIP_NAME="dartsdk-linux-x64-release.zip"
      ;;
    *)
      echo "Unknown operating system. Cannot install Dart SDK."
      exit 1
      ;;
  esac

  DART_CHANNEL="stable"

  if [[ $DART_SDK_VERSION == *"-dev."* ]]
  then
    DART_CHANNEL="dev"
  elif [[ $DART_SDK_VERSION == "hash/"* ]]
  then
    DART_CHANNEL="be"
  fi

  DART_SDK_URL="https://storage.googleapis.com/dart-archive/channels/$DART_CHANNEL/raw/$DART_SDK_VERSION/sdk/$DART_ZIP_NAME"

  rm -rf -- "$DART_SDK_PATH"
  mkdir -p -- "$DART_SDK_PATH"
  DART_SDK_ZIP="$FLUTTER_ROOT/bin/cache/dart-sdk.zip"

  curl -continue-at=- --location --output "$DART_SDK_ZIP" "$DART_SDK_URL" 2>&1
  unzip -o -q "$DART_SDK_ZIP" -d "$FLUTTER_ROOT/bin/cache" || {
    echo
    echo "It appears that the downloaded file is corrupt; please try the operation again later."
    echo "If this problem persists, please report the problem at"
    echo "https://github.com/flutter/flutter/issues/new"
    echo
    rm -f -- "$DART_SDK_ZIP"
    exit 1
  }
  rm -f -- "$DART_SDK_ZIP"
  echo "$DART_SDK_VERSION" > "$DART_SDK_STAMP_PATH"
fi
