#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script is currently used only by automation to collect and upload
# metrics and expects $ENGINE_PATH to be set.

set -ex

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
DART_SDK_DIR="${SRC_DIR}/third_party/dart/tools/sdks/dart-sdk"
DART="${DART_SDK_DIR}/bin/dart"

cd "$SCRIPT_DIR"
"$DART" --disable-dart-dev bin/parse_and_send.dart \
  --json $ENGINE_PATH/src/out/host_release/txt_benchmarks.json "$@"
"$DART" --disable-dart-dev bin/parse_and_send.dart \
  --json $ENGINE_PATH/src/out/host_release/fml_benchmarks.json "$@"
"$DART" --disable-dart-dev bin/parse_and_send.dart \
  --json $ENGINE_PATH/src/out/host_release/shell_benchmarks.json "$@"
"$DART" --disable-dart-dev bin/parse_and_send.dart \
  --json $ENGINE_PATH/src/out/host_release/ui_benchmarks.json "$@"
"$DART" --disable-dart-dev bin/parse_and_send.dart \
  --json $ENGINE_PATH/src/out/host_release/display_list_builder_benchmarks.json "$@"
"$DART" --disable-dart-dev bin/parse_and_send.dart \
  --json $ENGINE_PATH/src/out/host_release/geometry_benchmarks.json "$@"
