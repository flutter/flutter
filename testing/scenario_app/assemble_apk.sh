#!/bin/bash

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
SRC_DIR="$(cd "$SCRIPT_DIR/../../.."; pwd -P)"
export ANDROID_HOME="$SRC_DIR/third_party/android_tools/sdk"

"$SRC_DIR/flutter/tools/gn" --unopt
ninja -C "$SRC_DIR/out/host_debug_unopt" sky_engine -j 400

"$SCRIPT_DIR/compile_android_aot.sh" "$1" "$2"

(
  cd "$SCRIPT_DIR/android"
  ./gradlew assembleDebug --no-daemon
)

# LUCI expects to find the APK here
mkdir -p "$SCRIPT_DIR/android/app/build/outputs/apk/debug"
cp "$SCRIPT_DIR/build/app/outputs/apk/debug/app-debug.apk" "$SCRIPT_DIR/android/app/build/outputs/apk/debug"
