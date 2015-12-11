#!/usr/bin/env bash
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

GOMA_FLAGS="-j900"
if [[ -z "$GOMA_DIR" ]]; then
  GOMA_FLAGS=""
fi

# Remove all previous build artifacts
rm -rf out/

# Configure and build the iOS Simulator target
sky/tools/gn --ios --release --simulator
ninja -C out/ios_sim_Release ${GOMA_FLAGS}

# Configure and build the iOS Device target
sky/tools/gn --ios --release
ninja -C out/ios_Release ${GOMA_FLAGS}

# Create the directory for the merged project
mkdir -p out/FlutterXcode

# Merge build artifacts
cp -R out/ios_sim_Release/Flutter out/FlutterXcode
cp -R out/ios_Release/Flutter out/FlutterXcode

# Package it into a ZIP file for the builder to upload to cloud storage
pushd out/FlutterXcode
zip -r FlutterXcode.zip Flutter
popd
