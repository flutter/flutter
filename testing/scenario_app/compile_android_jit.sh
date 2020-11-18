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

HOST_TOOLS="$1"
DEVICE_TOOLS="$2"

if [[ ! -d "$HOST_TOOLS" ]]; then
  echo "Directory $HOST_TOOLS not found."
  echo "First argument must specify the host out directory containing dart (e.g. host_debug_unopt)."
  exit 1
fi

if [[ ! -d "$DEVICE_TOOLS" ]]; then
  echo "Directory $DEVICE_TOOLS not found."
  echo "Second argument must specify the device out directory containing gen_snapshot (e.g. android_debug_unopt_x64)."
  exit 1
fi

PUB="$HOST_TOOLS/dart-sdk/bin/pub"
PUB_VERSION="$("$PUB" --version)"
echo "Using Pub $PUB_VERSION from $PUB"

"$PUB" get

echo "Using dart from $HOST_TOOLS, gen_snapshot from $DEVICE_TOOLS."

OUTDIR="$SCRIPT_DIR/build/app"
FLUTTER_ASSETS_DIR="$OUTDIR/assets/flutter_assets"
LIBS_DIR="$SCRIPT_DIR/android/app/libs"
GEN_SNAPSHOT="$DEVICE_TOOLS/gen_snapshot"

if [[ ! -f "$GEN_SNAPSHOT" ]]; then
  GEN_SNAPSHOT="$DEVICE_TOOLS/gen_snapshot_host_targeting_host"
fi

if [[ ! -f "$GEN_SNAPSHOT" ]]; then
  echo "Could not find gen_snapshot in $DEVICE_TOOLS."
  exit 1
fi

echo "Creating directories..."

mkdir -p "$OUTDIR"
mkdir -p "$FLUTTER_ASSETS_DIR"
mkdir -p "$LIBS_DIR"

echo "Compiling kernel..."

"$HOST_TOOLS/dart" \
  "$HOST_TOOLS/gen/frontend_server.dart.snapshot" \
  --sdk-root "$HOST_TOOLS/flutter_patched_sdk" \
  --target=flutter \
  --no-link-platform \
  --output-dill "$FLUTTER_ASSETS_DIR/kernel_blob.bin" \
  "$SCRIPT_DIR/lib/main.dart"

echo "Compiling JIT Snapshot..."

"$GEN_SNAPSHOT" --deterministic \
  --enable-asserts \
  --no-causal_async_stacks \
  --lazy_async_stacks \
  --isolate_snapshot_instructions="$OUTDIR/isolate_snapshot_instr" \
  --snapshot_kind=app-jit \
  --load_vm_snapshot_data="$DEVICE_TOOLS/../gen/flutter/lib/snapshot/vm_isolate_snapshot.bin" \
  --load_isolate_snapshot_data="$DEVICE_TOOLS/../gen/flutter/lib/snapshot/isolate_snapshot.bin" \
  --isolate_snapshot_data="$FLUTTER_ASSETS_DIR/isolate_snapshot_data" \
  --isolate_snapshot_instructions="$FLUTTER_ASSETS_DIR/isolate_snapshot_instr" \
  "$FLUTTER_ASSETS_DIR/kernel_blob.bin"

cp "$DEVICE_TOOLS/../flutter.jar" "$LIBS_DIR"

echo "Created $OUTDIR."
