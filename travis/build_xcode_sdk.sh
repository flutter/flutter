#!/usr/bin/env bash
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

# When run using the Xcode Bot, the TARGET_TEMP_DIR variable is set. If not,
# use /tmp
WORKSPACE=${TARGET_TEMP_DIR}/tmp/flutter_build_workspace
DEPOT_WORKSPACE=${TARGET_TEMP_DIR}/tmp/flutter_depot_tools

function NukeWorkspace {
  rm -rf ${WORKSPACE}
  rm -rf ${DEPOT_WORKSPACE}
}

trap NukeWorkspace EXIT

NukeWorkspace

# Create a separate workspace for gclient
mkdir -p ${WORKSPACE}
cp -a . ${WORKSPACE}/src
cp travis/gclient ${WORKSPACE}/.gclient

# Move into the fresh workspace
pushd ${WORKSPACE}/src

# Setup Depot tools
rm -rf ${DEPOT_WORKSPACE}
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ${DEPOT_WORKSPACE}
PATH="${DEPOT_WORKSPACE}:$PATH"

# Sync dependencies
gclient sync

# Setup Goma if available
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

# When built for archiving, the DSTROOT is set by Xcode.
if [[ ! -z ${DSTROOT} ]]; then
  mv FlutterXcode.zip ${DSTROOT}
fi

popd # Out of the Xcode project

popd # Out of the workspace
