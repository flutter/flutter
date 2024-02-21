#!/bin/bash
#
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
SRC_DIR="$(cd "$SCRIPT_DIR/../.."; pwd -P)"
DART_SDK_DIR="${SRC_DIR}/third_party/dart/tools/sdks/dart-sdk"
DART="${DART_SDK_DIR}/bin/dart"

# Check if a file named **/GeneratedPluginRegistrant.java exists in the project.
# If it does, fail the build and print a message to the user pointing them to
# the file and instructing them to remove it.
#
# See: https://github.com/flutter/flutter/issues/143782.

# The expected path to the file. Any *other* path is unexpected.
EXPECTED_PATHS=("./shell/platform/android/test/io/flutter/plugins/GeneratedPluginRegistrant.java")

# Find all files named GeneratedPluginRegistrant.java in the project.
GENERATED_PLUGIN_REGISTRANT_PATHS=$(find "$SRC_DIR/flutter" -name "GeneratedPluginRegistrant.java")

# Check for GeneratedPluginRegistrant.java in unexpected locations
for expected_path in "${EXPECTED_PATHS[@]}"; do
    found_files=$(find . -name "GeneratedPluginRegistrant.java" -not -path "$expected_path")

    for file in $found_files; do
        echo "Error: Unexpected GeneratedPluginRegistrant.java found: $file"
        echo "Please remove the unexpected file and see: https://github.com/flutter/flutter/issues/143782"
        exit 1
    done
done

cd "$SCRIPT_DIR"
"$DART" \
  --disable-dart-dev \
  bin/format.dart \
  "$@"
