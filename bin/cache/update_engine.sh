#!/bin/bash
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

FLUTTER_ROOT=$(dirname $(dirname $(dirname "${BASH_SOURCE[0]}")))

ENGINE_STAMP_PATH="$FLUTTER_ROOT/bin/cache/engine.stamp"
ENGINE_VERSION=`cat "$FLUTTER_ROOT/bin/cache/engine.version"`

if [ ! -f "$ENGINE_STAMP_PATH" ] || [ "$ENGINE_VERSION" != `cat "$ENGINE_STAMP_PATH"` ]; then

  BASE_URL="https://storage.googleapis.com/flutter_infra/flutter/$ENGINE_VERSION"
  PKG_PATH="$FLUTTER_ROOT/bin/cache/pkg"
  mkdir -p -- "$PKG_PATH"

  # sky_engine Package

  echo "Downloading Flutter engine $ENGINE_VERSION..."
  ENGINE_PKG_URL="$BASE_URL/sky_engine.zip"
  ENGINE_PKG_ZIP="$FLUTTER_ROOT/bin/cache/sky_engine.zip"
  curl --progress-bar -continue-at=- --location --output "$ENGINE_PKG_ZIP" "$ENGINE_PKG_URL"
  rm -rf -- "$PKG_PATH/sky_engine"
  unzip -o -q "$ENGINE_PKG_ZIP" -d "$PKG_PATH"
  rm -f -- "$ENGINE_PKG_ZIP"

  # sky_services Package

  echo "  And corresponding services package..."
  SERVICES_PKG_URL="$BASE_URL/sky_services.zip"
  SERVICES_PKG_ZIP="$FLUTTER_ROOT/bin/cache/sky_services.zip"
  curl --progress-bar -continue-at=- --location --output "$SERVICES_PKG_ZIP" "$SERVICES_PKG_URL"
  rm -rf -- "$PKG_PATH/sky_services"
  unzip -o -q "$SERVICES_PKG_ZIP" -d "$PKG_PATH"
  rm -f -- "$SERVICES_PKG_ZIP"

  # Binary artifacts

  ENGINE_ARTIFACT_PATH="$FLUTTER_ROOT/bin/cache/artifacts/engine"
  rm -rf -- "$ENGINE_ARTIFACT_PATH"

  download_artifacts() {
    PLATFORM="$1"

    PLATFORM_PATH="$ENGINE_ARTIFACT_PATH/$PLATFORM"
    mkdir -p -- "$PLATFORM_PATH"

    echo "  And corresponding toolchain for $PLATFORM..."
    ARTIFACTS_URL="$BASE_URL/$PLATFORM/artifacts.zip"
    ARTIFACTS_ZIP="$PLATFORM_PATH/artifacts.zip"
    curl --progress-bar -continue-at=- --location --output "$ARTIFACTS_ZIP" "$ARTIFACTS_URL"
    unzip -o -q "$ARTIFACTS_ZIP" -d "$PLATFORM_PATH"
    rm -f -- "$ARTIFACTS_ZIP"
  }

  download_artifacts android-arm

  case "$(uname -s)" in
    Darwin)
      download_artifacts darwin-x64
      chmod a+x "$ENGINE_ARTIFACT_PATH/darwin-x64/sky_snapshot"
      download_artifacts ios
      ;;
    Linux)
      download_artifacts linux-x64
      chmod a+x "$ENGINE_ARTIFACT_PATH/linux-x64/sky_shell"
      chmod a+x "$ENGINE_ARTIFACT_PATH/linux-x64/sky_snapshot"
      ;;
  esac

  echo "$ENGINE_VERSION" > "$ENGINE_STAMP_PATH"
fi
