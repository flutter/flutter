#!/bin/bash
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

FLUTTER_ROOT=$(dirname $(dirname $(dirname "${BASH_SOURCE[0]}")))

MATERIAL_FONTS_STAMP_PATH="$FLUTTER_ROOT/bin/cache/material_fonts.stamp"
MATERIAL_FONTS_VERSION=`cat "$FLUTTER_ROOT/bin/cache/material_fonts.version"`

if [ ! -f "$MATERIAL_FONTS_STAMP_PATH" ] || [ "$MATERIAL_FONTS_VERSION" != `cat "$MATERIAL_FONTS_STAMP_PATH"` ]; then
  echo "Downloading Material Design fonts..."

  MATERIAL_FONTS_URL="$MATERIAL_FONTS_VERSION"
  MATERIAL_FONTS_PATH="$FLUTTER_ROOT/bin/cache/artifacts/material_fonts"
  MATERIAL_FONTS_ZIP="$FLUTTER_ROOT/bin/cache/material_fonts.zip"

  mkdir -p -- "$MATERIAL_FONTS_PATH"

  curl --progress-bar -continue-at=- --location --output "$MATERIAL_FONTS_ZIP" "$MATERIAL_FONTS_URL"
  rm -rf -- "$MATERIAL_FONTS_PATH"
  unzip -o -q "$MATERIAL_FONTS_ZIP" -d "$MATERIAL_FONTS_PATH"
  rm -f -- "$MATERIAL_FONTS_ZIP"

  echo "$MATERIAL_FONTS_VERSION" > "$MATERIAL_FONTS_STAMP_PATH"
fi
