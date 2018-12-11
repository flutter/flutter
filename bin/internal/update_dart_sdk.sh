#!/usr/bin/env bash
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
DART_SDK_PATH_OLD="$DART_SDK_PATH.old"
ENGINE_STAMP="$FLUTTER_ROOT/bin/cache/engine-dart-sdk.stamp"
ENGINE_VERSION=`cat "$FLUTTER_ROOT/bin/internal/engine.version"`

if [ ! -f "$ENGINE_STAMP" ] || [ "$ENGINE_VERSION" != `cat "$ENGINE_STAMP"` ]; then
  echo "Downloading Dart SDK from Flutter engine $ENGINE_VERSION..."

  case "$(uname -s)" in
    Darwin)
      DART_ZIP_NAME="dart-sdk-darwin-x64.zip"
      ;;
    Linux)
      DART_ZIP_NAME="dart-sdk-linux-x64.zip"
      ;;
    *)
      echo "Unknown operating system. Cannot install Dart SDK."
      exit 1
      ;;
  esac

  DART_SDK_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.googleapis.com}"
  DART_SDK_URL="$DART_SDK_BASE_URL/flutter_infra/flutter/$ENGINE_VERSION/$DART_ZIP_NAME"

  # if the sdk path exists, copy it to a temporary location
  if [ -d "$DART_SDK_PATH" ]; then
    rm -rf "$DART_SDK_PATH_OLD"
    mv "$DART_SDK_PATH" "$DART_SDK_PATH_OLD"
  fi

  # install the new sdk
  rm -rf -- "$DART_SDK_PATH"
  mkdir -p -- "$DART_SDK_PATH"
  DART_SDK_ZIP="$FLUTTER_ROOT/bin/cache/$DART_ZIP_NAME"

  curl --continue-at - --location --output "$DART_SDK_ZIP" "$DART_SDK_URL" 2>&1 || {
    echo
    echo "Failed to retrieve the Dart SDK at $DART_SDK_URL"
    echo "If you're located in China, please follow"
    echo "https://github.com/flutter/flutter/wiki/Using-Flutter-in-China"
    echo
    rm -f -- "$DART_SDK_ZIP"
    exit 1
  }
  unzip -o -q "$DART_SDK_ZIP" -d "$FLUTTER_ROOT/bin/cache" || {
    echo
    echo "It appears that the downloaded file is corrupt; please try the operation again later."
    echo "If this problem persists, please report the problem at"
    echo "https://github.com/flutter/flutter/issues/new?template=ACTIVATION.md"
    echo
    rm -f -- "$DART_SDK_ZIP"
    exit 1
  }
  rm -f -- "$DART_SDK_ZIP"
  echo "$ENGINE_VERSION" > "$ENGINE_STAMP"

  # delete any temporary sdk path
  if [ -d "$DART_SDK_PATH_OLD" ]; then
    rm -rf "$DART_SDK_PATH_OLD"
  fi
fi
