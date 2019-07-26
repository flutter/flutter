#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

#TODO(dnfield): Get rid of this script and instead use proper build rules

set -e

HOST_TOOLS=$1
DEVICE_TOOLS=$2

if [[ ! -d "$HOST_TOOLS" ]]; then
  echo "Must specify the host out directory containing dart."
  exit 1
fi

if [[ ! -d "$DEVICE_TOOLS" ]]; then
  echo "Must specify the device out directory containing gen_snapshot."
  exit 1
fi

echo "Using dart from $HOST_TOOLS, gen_snapshot from $DEVICE_TOOLS."

OUTDIR="build/android"

echo "Creating $OUTDIR..."

mkdir -p $OUTDIR

echo "Compiling kernel..."

"$HOST_TOOLS/dart" \
  "$HOST_TOOLS/gen/frontend_server.dart.snapshot" \
  --sdk-root "$HOST_TOOLS/flutter_patched_sdk" \
  --aot --tfa --target=flutter \
  --output-dill "$OUTDIR/app.dill" \
  lib/main.dart

echo "Compiling ELF Shared Library..."

"$DEVICE_TOOLS/gen_snapshot" --deterministic --snapshot_kind=app-aot-elf --elf="$OUTDIR/libapp.so" --strip "$OUTDIR/app.dill"

mkdir -p "android/app/src/main/jniLibs/arm64-v8a"
mkdir -p "android/app/libs"
cp "$OUTDIR/libapp.so" "android/app/src/main/jniLibs/arm64-v8a/"
cp "$DEVICE_TOOLS/../flutter.jar" "android/app/libs/"

echo "Created $OUTDIR/libapp.so."
