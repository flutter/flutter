#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

#TODO(dnfield): Get rid of this script and instead use proper build rules

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

HOST_TOOLS="$1"
DEVICE_TOOLS="$2"

if [[ ! -d "$HOST_TOOLS" ]]; then
  echo "Directory $HOST_TOOLS not found."
  echo "First argument must specify the host out directory containing dart (e.g. out/host_debug_unopt)."
  exit 1
fi

if [[ ! -d "$DEVICE_TOOLS" ]]; then
  echo "Directory $DEVICE_TOOLS not found."
  ehco "Second argument must specify the device out directory containing gen_snapshot (e.g. out/android_debug_unopt_x64/clang_x64)."
  exit 1
fi

PUB="$HOST_TOOLS/dart-sdk/bin/pub"
PUB_VERSION="$("$PUB" --version)"
echo "Using Pub ${PUB_VERSION} from $PUB"

(cd "$SCRIPT_DIR"; "$PUB" get)

echo "Using dart from $HOST_TOOLS, gen_snapshot from $DEVICE_TOOLS."

OUTDIR="$SCRIPT_DIR/build/android"

echo "Creating $OUTDIR..."

mkdir -p "$OUTDIR"

echo "Compiling kernel..."

"$HOST_TOOLS/dart" \
  "$HOST_TOOLS/gen/frontend_server.dart.snapshot" \
  --sdk-root "$HOST_TOOLS/flutter_patched_sdk" \
  --aot --tfa --target=flutter \
  --output-dill "$OUTDIR/app.dill" \
  "$SCRIPT_DIR/lib/main.dart"

echo "Compiling ELF Shared Library..."

"$HOST_TOOLS/gen_snapshot" --deterministic --snapshot_kind=app-aot-elf --elf="$OUTDIR/libapp.so" --strip "$OUTDIR/app.dill"

mkdir -p "$SCRIPT_DIR/android/app/src/main/jniLibs/arm64-v8a"
mkdir -p "$SCRIPT_DIR/android/app/libs"
cp "$OUTDIR/libapp.so" "$SCRIPT_DIR/android/app/src/main/jniLibs/arm64-v8a/"
cp "$DEVICE_TOOLS/../flutter.jar" "$SCRIPT_DIR/android/app/libs/"

echo "Created $OUTDIR/libapp.so."
