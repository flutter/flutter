#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

# On Mac OS, readlink -f doesn't work, so follow_links traverses the path one
# link at a time, and then cds into the link destination and find out where it
# ends up.
#
# The function is enclosed in a subshell to avoid changing the working directory
# of the caller.
function follow_links() (
  cd -P "$(dirname -- "$1")"
  file="$PWD/$(basename -- "$1")"
  while [[ -h "$file" ]]; do
    cd -P "$(dirname -- "$file")"
    file="$(readlink -- "$file")"
    cd -P "$(dirname -- "$file")"
    file="$PWD/$(basename -- "$file")"
  done
  echo "$file"
)

SCRIPT_DIR=$(follow_links "$(dirname -- "${BASH_SOURCE[0]}")")
SRC_DIR="$(cd "$SCRIPT_DIR/../../.."; pwd -P)"
GN="$SRC_DIR/flutter/tools/gn"

FLUTTER_ENGINE=android_debug_unopt_x64
export ANDROID_HOME="$SRC_DIR/third_party/android_tools/sdk"

if [[ $# -eq 1 ]]; then
  FLUTTER_ENGINE="$1"
fi

if [[ ! -d "$SRC_DIR/out/$FLUTTER_ENGINE" ]]; then
  "$GN" --android --unoptimized --android-cpu x64 --runtime-mode debug
  "$GN" --unoptimized --runtime-mode debug
fi

autoninja -C "$SRC_DIR/out/$FLUTTER_ENGINE"
autoninja -C "$SRC_DIR/out/host_debug_unopt"

"$SCRIPT_DIR/compile_android_jit.sh" "$SRC_DIR/out/host_debug_unopt" "$SRC_DIR/out/$FLUTTER_ENGINE/clang_x64"
"$SCRIPT_DIR/run_android_tests.sh" "$FLUTTER_ENGINE"
