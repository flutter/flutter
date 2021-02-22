#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
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
  command -v curl > /dev/null 2>&1 || {
    >&2 echo
    >&2 echo 'Missing "curl" tool. Unable to download Dart SDK.'
    case "$(uname -s)" in
      Darwin)
        >&2 echo 'Consider running "brew install curl".'
        ;;
      Linux)
        >&2 echo 'Consider running "sudo apt-get install curl".'
        ;;
      *)
        >&2 echo "Please install curl."
        ;;
    esac
    echo
    exit 1
  }
  command -v unzip > /dev/null 2>&1 || {
    >&2 echo
    >&2 echo 'Missing "unzip" tool. Unable to extract Dart SDK.'
    case "$(uname -s)" in
      Darwin)
        echo 'Consider running "brew install unzip".'
        ;;
      Linux)
        echo 'Consider running "sudo apt-get install unzip".'
        ;;
      *)
        echo "Please install unzip."
        ;;
    esac
    echo
    exit 1
  }
  >&2 echo "Downloading Dart SDK from Flutter engine $ENGINE_VERSION..."

  # On x64 stdout is "uname -m: x86_64"
  # On arm64 stdout is "uname -m: aarch64, arm64_v8a"
  case "$(uname -m)" in
    x86_64)
      ARCH="x64"
      ;;
    *)
      ARCH="arm64"
      ;;
  esac

  case "$(uname -s)" in
    Darwin)
      DART_ZIP_NAME="dart-sdk-darwin-x64.zip"
      IS_USER_EXECUTABLE="-perm +100"
      ;;
    Linux)
      DART_ZIP_NAME="dart-sdk-linux-${ARCH}.zip"
      IS_USER_EXECUTABLE="-perm /u+x"
      ;;
    MINGW*)
      DART_ZIP_NAME="dart-sdk-windows-x64.zip"
      IS_USER_EXECUTABLE="-perm /u+x"
      ;;
    *)
      echo "Unknown operating system. Cannot install Dart SDK."
      exit 1
      ;;
  esac

  # Use the default find if possible.
  if [ -e /usr/bin/find ]; then
    FIND=/usr/bin/find
  else
    FIND=find
  fi

  DART_SDK_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.googleapis.com}"
  DART_SDK_URL="$DART_SDK_BASE_URL/flutter_infra_release/flutter/$ENGINE_VERSION/$DART_ZIP_NAME"

  # if the sdk path exists, copy it to a temporary location
  if [ -d "$DART_SDK_PATH" ]; then
    rm -rf "$DART_SDK_PATH_OLD"
    mv "$DART_SDK_PATH" "$DART_SDK_PATH_OLD"
  fi

  # install the new sdk
  rm -rf -- "$DART_SDK_PATH"
  mkdir -m 755 -p -- "$DART_SDK_PATH"
  DART_SDK_ZIP="$FLUTTER_ROOT/bin/cache/$DART_ZIP_NAME"

  curl --retry 3 --continue-at - --location --output "$DART_SDK_ZIP" "$DART_SDK_URL" 2>&1 || {
    >&2 echo
    >&2 echo "Failed to retrieve the Dart SDK from: $DART_SDK_URL"
    >&2 echo "If you're located in China, please see this page:"
    >&2 echo "  https://flutter.dev/community/china"
    >&2 echo
    rm -f -- "$DART_SDK_ZIP"
    exit 1
  }
  unzip -o -q "$DART_SDK_ZIP" -d "$FLUTTER_ROOT/bin/cache" || {
    >&2 echo
    >&2 echo "It appears that the downloaded file is corrupt; please try again."
    >&2 echo "If this problem persists, please report the problem at:"
    >&2 echo "  https://github.com/flutter/flutter/issues/new?template=ACTIVATION.md"
    >&2 echo
    rm -f -- "$DART_SDK_ZIP"
    exit 1
  }
  rm -f -- "$DART_SDK_ZIP"
  $FIND "$DART_SDK_PATH" -type d -exec chmod 755 {} \;
  $FIND "$DART_SDK_PATH" -type f $IS_USER_EXECUTABLE -exec chmod a+x,a+r {} \;
  echo "$ENGINE_VERSION" > "$ENGINE_STAMP"

  # delete any temporary sdk path
  if [ -d "$DART_SDK_PATH_OLD" ]; then
    rm -rf "$DART_SDK_PATH_OLD"
  fi
fi
