#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is executed by the skia autoroller after the roll has happened but before
# the PR is uploaded. Previously this logic was hardcoded into the autoroller
# and was reserved for updating the LICENSE file. Now the autoroller delegates
# to this script.
# See also:
#   - https://skia-review.googlesource.com/c/buildbot/+/1025936
#   - https://issues.skia.org/issues/433551375

REPO_PATH=$(dirname "$(readlink -f "$0")")
ET="$REPO_PATH/engine/src/flutter/bin/et"
LICENSE_CPP="$REPO_PATH/engine/src/out/host_profile/licenses_cpp"
WORKING_DIR="$REPO_PATH/engine/src/flutter"
LICENSES_PATH="$REPO_PATH/engine/src/flutter/sky/packages/sky_engine/LICENSE"
DATA_PATH="$REPO_PATH/engine/src/flutter/tools/licenses_cpp/data"

$ET build --no-rbe -c host_profile //flutter/tools/licenses_cpp
$LICENSE_CPP \
  --working_dir=$WORKING_DIR \
  --licenses_path=$LICENSES_PATH \
  --data_dir=$DATA_PATH \
  --v=1
