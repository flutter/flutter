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

OUTDIR="${BASH_SOURCE%/*}/build/ios"

echo "Creating $OUTDIR..."

mkdir -p "$OUTDIR"
mkdir -p "$OUTDIR/App.framework/flutter_assets"

echo "Compiling to kernel..."

"$HOST_TOOLS/dart" \
  "$HOST_TOOLS/gen/frontend_server.dart.snapshot" \
  --sdk-root "$HOST_TOOLS/flutter_patched_sdk" \
  --strong --target=flutter \
  --no-link-platform \
  --output-dill "$OUTDIR/App.framework/flutter_assets/kernel_blob.bin" \
  "${BASH_SOURCE%/*}/lib/main.dart"

echo "Compiling JIT Snapshot..."

"$DEVICE_TOOLS/gen_snapshot" --deterministic \
  --enable-asserts \
  --causal_async_stacks \
  --isolate_snapshot_instructions="$OUTDIR/isolate_snapshot_instr" \
  --snapshot_kind=app-jit \
  --load_vm_snapshot_data="$DEVICE_TOOLS/../gen/flutter/lib/snapshot/vm_isolate_snapshot.bin" \
  --load_isolate_snapshot_data="$DEVICE_TOOLS/../gen/flutter/lib/snapshot/isolate_snapshot.bin" \
  --isolate_snapshot_data="$OUTDIR/App.framework/flutter_assets/isolate_snapshot_data" \
  --isolate_snapshot_instructions="$OUTDIR/App.framework/flutter_assets/isolate_snapshot_instr" \
  "$OUTDIR/App.framework/flutter_assets/kernel_blob.bin"

cp "$DEVICE_TOOLS/../gen/flutter/lib/snapshot/vm_isolate_snapshot.bin" "$OUTDIR/App.framework/flutter_assets/vm_snapshot_data"

SYSROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
echo "Using $SYSROOT as sysroot."

echo "Creating stub App using $SYSROOT..."

echo "static const int Moo = 88;" | xcrun clang -x c \
  -arch x86_64 \
  -isysroot "$SYSROOT" \
  -miphoneos-version-min=8.0 \
  -dynamiclib \
  -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
  -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
  -install_name '@rpath/App.framework/App' \
  -o "$OUTDIR/App.framework/App" -

strip "$OUTDIR/App.framework/App"

cp "${BASH_SOURCE%/*}/ios/AppFrameworkInfo.plist" "$OUTDIR/App.framework/Info.plist"
echo "Created $OUTDIR/App.framework/App."

rm -rf "${BASH_SOURCE%/*}/ios/Scenarios/App.framework"
rm -rf "${BASH_SOURCE%/*}/ios/Scenarios/Flutter.framework"
cp -R "$OUTDIR/App.framework" "${BASH_SOURCE%/*}/ios/Scenarios"
cp -R "$DEVICE_TOOLS/../Flutter.framework" "${BASH_SOURCE%/*}/ios/Scenarios"

