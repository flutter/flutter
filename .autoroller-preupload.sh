#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# This is executed by the skia autoroller after the roll has happened but before
# the PR is uploaded. Previously this logic was hardcoded into the autoroller
# and was reserved for updating the LICENSE file. Now the autoroller delegates
# to this script.
# See also:
#   - https://skia-review.googlesource.com/c/buildbot/+/1025936
#   - https://issues.skia.org/issues/433551375

REPO_PATH=$(dirname "$(readlink -f "$0")")
PROFILE_PATH="$REPO_PATH/engine/src/out/host_profile"
GN="$REPO_PATH/engine/src/flutter/tools/gn"
LICENSE_CPP="$REPO_PATH/engine/src/out/host_profile/licenses_cpp"
WORKING_DIR="$REPO_PATH/engine/src"
LICENSES_PATH="$REPO_PATH/engine/src/flutter/sky/packages/sky_engine/LICENSE"
DATA_PATH="$REPO_PATH/engine/src/flutter/tools/licenses_cpp/data"

cd "$REPO_PATH/engine/src"
./tools/dart/create_updated_flutter_deps.py
cd "$REPO_PATH"
gclient sync -D

# This calls `gn gen`.
"$GN" --runtime-mode profile --no-goma --no-rbe --enable-minimal-linux
ninja -C "$PROFILE_PATH" licenses_cpp
"$LICENSE_CPP" \
  --working_dir="$WORKING_DIR" \
  --licenses_path="$LICENSES_PATH" \
  --data_dir="$DATA_PATH" \
  --root_package="flutter" \
  --v=1
