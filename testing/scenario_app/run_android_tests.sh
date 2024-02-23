#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs the Android scenario tests on a connected device.
#   To run the test on a x64 emulator, build `android_debug_unopt_x64`, and then run
#   `./run_android_tests.sh android_debug_unopt_x64`.

set -e

# Check number of args.
if [ $# -lt 1 ]; then
  echo "Usage: $0 <variant> [flags*]"
  exit 1
fi

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

BUILD_VARIANT=$1

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
SRC_DIR="$(
  cd "$SCRIPT_DIR/../../.."
  pwd -P
)"
OUT_DIR="$SRC_DIR/out/$BUILD_VARIANT"
CONTENTS_GOLDEN="$SRC_DIR/flutter/testing/scenario_app_android_output.txt"

# TODO(matanlurey): If the test runner was purely in Dart, this would not have
# been necesesary to repeat. However my best guess is the Dart script was seen
# as potentially crashing, so it was wrapped in a shell script. If we can change
# this, we should.
#
# Define a logs directory for ADB and screenshots.
# By default, it should be the environment variable FLUTTER_LOGS_DIR, but if
# it's not set, use the output directory and append "scenario_app/logs".
LOGS_DIR=${FLUTTER_LOGS_DIR:-"$OUT_DIR/scenario_app/logs"}

# Create the logs directory if it doesn't exist.
mkdir -p "$LOGS_DIR"

# Dump the logcat and symbolize stack traces before exiting.
function dumpLogcat {
  ndkstack="windows-x86_64"
  if [ "$(uname)" == "Darwin" ]; then
    ndkstack="darwin-x86_64"
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    ndkstack="linux-x86_64"
  fi

  # Get the expected location of logcat.txt.
  logcat_file="$LOGS_DIR/logcat.txt"

  echo "-> Symbolize stack traces"
  "$SRC_DIR"/third_party/android_tools/ndk/prebuilt/"$ndkstack"/bin/ndk-stack \
    -sym "$OUT_DIR" \
    -dump "$logcat_file"
  echo "<- Done"

  # Output the directory for the logs.
  echo "TIP: Full logs are in $LOGS_DIR"
}

# On error, dump the logcat and symbolize stack traces.
trap dumpLogcat ERR

cd $SCRIPT_DIR

"$SRC_DIR"/third_party/dart/tools/sdks/dart-sdk/bin/dart pub get

"$SRC_DIR"/third_party/dart/tools/sdks/dart-sdk/bin/dart run \
  "$SCRIPT_DIR"/bin/android_integration_tests.dart \
  --out-dir="$OUT_DIR" \
  --logs-dir="$LOGS_DIR" \
  --output-contents-golden="$CONTENTS_GOLDEN" \
  "$@"
