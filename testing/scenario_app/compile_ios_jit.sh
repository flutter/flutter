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
  echo "First argument must specify the host out directory containing dart (e.g. host_debug_unopt)."
  exit 1
fi

if [[ ! -d "$DEVICE_TOOLS" ]]; then
  echo "Directory $DEVICE_TOOLS not found."
  ehco "Second argument must specify the device out directory containing gen_snapshot (e.g. ios_debug_unopt)."
  exit 1
fi

PUB="$HOST_TOOLS/dart-sdk/bin/pub"
PUB_VERSION=$("$PUB" --version)
echo "Using Pub $PUB_VERSION from $PUB"

"$PUB" get

echo "Using dart from $HOST_TOOLS, gen_snapshot from $DEVICE_TOOLS."

OUTDIR="$SCRIPT_DIR/build/ios"

echo "Creating $OUTDIR..."

mkdir -p "$OUTDIR"
mkdir -p "$OUTDIR/App.framework/flutter_assets"

echo "Compiling to kernel..."

"$HOST_TOOLS/dart" \
  "$HOST_TOOLS/gen/frontend_server.dart.snapshot" \
  --sdk-root "$HOST_TOOLS/flutter_patched_sdk" \
  --target=flutter \
  --no-link-platform \
  --output-dill "$OUTDIR/App.framework/flutter_assets/kernel_blob.bin" \
  "${BASH_SOURCE%/*}/lib/main.dart"

echo "Compiling JIT Snapshot..."

"$DEVICE_TOOLS/gen_snapshot" --deterministic \
  --enable-asserts \
  --no-causal_async_stacks \
  --lazy_async_stacks \
  --isolate_snapshot_instructions="$OUTDIR/isolate_snapshot_instr" \
  --snapshot_kind=app-jit \
  --load_vm_snapshot_data="$DEVICE_TOOLS/../gen/flutter/lib/snapshot/vm_isolate_snapshot.bin" \
  --load_isolate_snapshot_data="$DEVICE_TOOLS/../gen/flutter/lib/snapshot/isolate_snapshot.bin" \
  --isolate_snapshot_data="$OUTDIR/App.framework/flutter_assets/isolate_snapshot_data" \
  --isolate_snapshot_instructions="$OUTDIR/App.framework/flutter_assets/isolate_snapshot_instr" \
  "$OUTDIR/App.framework/flutter_assets/kernel_blob.bin"

cp "$DEVICE_TOOLS/../gen/flutter/lib/snapshot/vm_isolate_snapshot.bin" "$OUTDIR/App.framework/flutter_assets/vm_snapshot_data"

LLVM_BIN_PATH="${SCRIPT_DIR}/../../../buildtools/mac-x64/clang/bin"
SYSROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
echo "Using $SYSROOT as sysroot."

echo "Creating stub App using $SYSROOT..."

# Use buildroot clang so we can override the linker to use in our LUCI recipe.
# See: https://github.com/flutter/flutter/issues/65901
echo "static const int Moo = 88;" | "$LLVM_BIN_PATH/clang" -x c \
  -arch x86_64 \
  -fembed-bitcode-marker \
  -isysroot "$SYSROOT" \
  -miphoneos-version-min=8.0 \
  -dynamiclib \
  -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
  -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
  -install_name '@rpath/App.framework/App' \
  -o "$OUTDIR/App.framework/App" -

strip "$OUTDIR/App.framework/App"

cp "$SCRIPT_DIR/ios/AppFrameworkInfo.plist" "$OUTDIR/App.framework/Info.plist"
echo "Created $OUTDIR/App.framework/App."

rm -rf "$SCRIPT_DIR/ios/Scenarios/App.framework"
rm -rf "$SCRIPT_DIR/ios/Scenarios/Flutter.xcframework"
cp -R "$OUTDIR/App.framework" "$SCRIPT_DIR/ios/Scenarios"
cp -R "$DEVICE_TOOLS/../Flutter.xcframework" "$SCRIPT_DIR/ios/Scenarios"
