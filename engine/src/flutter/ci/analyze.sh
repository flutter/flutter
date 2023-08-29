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
  while [[ -L "$file" ]]; do
    cd -P "$(dirname -- "$file")"
    file="$(readlink -- "$file")"
    cd -P "$(dirname -- "$file")"
    file="$PWD/$(basename -- "$file")"
  done
  echo "$file"
)

SCRIPT_DIR=$(follow_links "$(dirname -- "${BASH_SOURCE[0]}")")
SRC_DIR="$(cd "$SCRIPT_DIR/../.."; pwd -P)"
FLUTTER_DIR="$SRC_DIR/flutter"
DART_BIN="$SRC_DIR/out/host_debug_unopt/dart-sdk/bin"
DART="$DART_BIN/dart"

if [[ ! -f "$DART" ]]; then
  echo "'$DART' not found"
  echo ""
  echo "To build the Dart SDK, run:"
  echo "  flutter/tools/gn --unoptimized --runtime-mode=debug"
  echo "  ninja -C out/host_debug_unopt"
  exit 1
fi

echo "Using dart from $DART_BIN"
"$DART" --version
echo ""

"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/ci"
"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/flutter_frontend_server"
"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/impeller/golden_tests_harvester"
"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/impeller/tessellator/dart"
"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/lib/gpu"
"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/lib/ui"
"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/testing"
"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/tools"

echo ""

# Check that dart libraries conform.
echo "Checking the integrity of the Web SDK"
(cd "$FLUTTER_DIR/web_sdk"; "$DART" pub get)
(cd "$FLUTTER_DIR/web_sdk/web_test_utils"; "$DART" pub get)
(cd "$FLUTTER_DIR/web_sdk/web_engine_tester"; "$DART" pub get)

"$DART" analyze --fatal-infos --fatal-warnings "$FLUTTER_DIR/web_sdk"

WEB_SDK_TEST_FILES="$FLUTTER_DIR/web_sdk/test/*"
for testFile in $WEB_SDK_TEST_FILES
do
  echo "Running $testFile"
  (cd "$FLUTTER_DIR"; FLUTTER_DIR="$FLUTTER_DIR" "$DART" --enable-asserts $testFile)
done
