#!/usr/bin/env bash
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -ex

# When run using the Xcode Bot, the TARGET_TEMP_DIR variable is set. If not,
# use /tmp
WORKSPACE=${TARGET_TEMP_DIR}/tmp/flutter_build_workspace
DEPOT_WORKSPACE=${TARGET_TEMP_DIR}/tmp/flutter_depot_tools
SERVICES_SDK_DIR=FlutterServicesSDK
SERVICES_ARCHIVE=${SERVICES_SDK_DIR}.zip

function NukeWorkspace {
  rm -rf ${WORKSPACE}
  rm -rf ${DEPOT_WORKSPACE}
}

trap NukeWorkspace EXIT

NukeWorkspace

# Figure out the engine release SHA
ENGINE_SHA="$(git rev-parse HEAD)"

if [[ -z "$ENGINE_SHA" ]]; then
  exit 1
fi

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

pushd out/

# Package up the services SDK

mkdir -p ${SERVICES_SDK_DIR}/include/mojo/public
mkdir -p ${SERVICES_SDK_DIR}/lib

# Create the fat services binary

lipo -create                                                      \
    ios_sim_Release/obj/sky/services/dynamic/libFlutterServices.a \
    ios_Release/obj/sky/services/dynamic/libFlutterServices.a     \
    -output ${SERVICES_SDK_DIR}/lib/libFlutterServicesIOS.a

# Copy all relevant headers

rsync -a --prune-empty-dirs --include '*/' --include '*.h' --exclude '*' \
    ../mojo/public/c ${SERVICES_SDK_DIR}/include/mojo/public
rsync -a --prune-empty-dirs --include '*/' --include '*.h' --exclude '*' \
    ../mojo/public/cpp ${SERVICES_SDK_DIR}/include/mojo/public
cp ../sky/services/dynamic/dynamic_service_dylib.h                       \
    ${SERVICES_SDK_DIR}/include/FlutterService.h

# Create the service archive

zip -r ${SERVICES_ARCHIVE} ${SERVICES_SDK_DIR}/

popd # Out of the out/ directory

# Create the directory for the merged project
mkdir -p out/FlutterXcode

# Merge build artifacts
cp -R out/ios_sim_Release/Flutter out/FlutterXcode
cp -R out/ios_Release/Flutter out/FlutterXcode

# Package it into a ZIP file for the builder to upload to cloud storage
pushd out/FlutterXcode

zip -r FlutterXcode.zip Flutter

# Upload generated assets if the key to the service account is available
if [[ ! -z ${BUCKET_KEY_FILE} ]]; then
  set +e
  GCLOUD_CMD="$(command -v gcloud)"
  set -e
  if [[ -z GCLOUD_CMD ]]; then
    CLOUDSDK_CORE_DISABLE_PROMPTS=1
    curl https://sdk.cloud.google.com | bash
  fi
  gcloud auth activate-service-account --key-file ${BUCKET_KEY_FILE}
  gsutil cp FlutterXcode.zip gs://flutter_infra/flutter/${ENGINE_SHA}/ios/FlutterXcode.zip
  gsutil cp ../${SERVICES_ARCHIVE} gs://flutter_infra/flutter/${ENGINE_SHA}/ios/${SERVICES_ARCHIVE}
fi

popd # Out of the Xcode project

popd # Out of the workspace
