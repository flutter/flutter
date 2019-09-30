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

PUB_VERSION=$($HOST_TOOLS/dart-sdk/bin/pub --version)
echo "Using Pub ${PUB_VERSION} from $HOST_TOOLS/dart-sdk/bin/pub"

$HOST_TOOLS/dart-sdk/bin/pub get

echo "Using dart from $HOST_TOOLS, gen_snapshot from $DEVICE_TOOLS."

OUTDIR="${BASH_SOURCE%/*}/build/ios"

echo "Creating $OUTDIR..."

mkdir -p $OUTDIR
mkdir -p "$OUTDIR/App.framework"

echo "Compiling kernel..."

"$HOST_TOOLS/dart" \
  "$HOST_TOOLS/gen/frontend_server.dart.snapshot" \
  --sdk-root "$HOST_TOOLS/flutter_patched_sdk" \
  --aot --tfa --target=flutter \
  --output-dill "$OUTDIR/app.dill" \
  "${BASH_SOURCE%/*}/lib/main.dart"

echo "Compiling AOT Assembly..."

"$DEVICE_TOOLS/gen_snapshot" --deterministic --snapshot_kind=app-aot-assembly --assembly=$OUTDIR/snapshot_assembly.S $OUTDIR/app.dill

SYSROOT=$(xcrun --sdk iphoneos --show-sdk-path)
echo "Using $SYSROOT as sysroot."
echo "Compiling Assembly..."

cc -arch arm64 \
  -fembed-bitcode \
  -isysroot "$SYSROOT" \
  -miphoneos-version-min=8.0 \
  -c "$OUTDIR/snapshot_assembly.S" \
  -o "$OUTDIR/snapshot_assembly.o"

echo "Linking App using $SYSROOT..."

clang -arch arm64 \
  -fembed-bitcode \
  -isysroot "$SYSROOT" \
  -miphoneos-version-min=8.0 \
  -dynamiclib -Xlinker -rpath -Xlinker @executable_path/Frameworks \
  -Xlinker -rpath -Xlinker @loader_path/Frameworks \
  -install_name @rpath/App.framework/App \
  -o "$OUTDIR/App.framework/App" \
  "$OUTDIR/snapshot_assembly.o"

strip "$OUTDIR/App.framework/App"

cp "${BASH_SOURCE%/*}/ios/AppFrameworkInfo.plist" "$OUTDIR/App.framework/Info.plist"

echo "Created $OUTDIR/App.framework/App."

rm -rf "${BASH_SOURCE%/*}/ios/Scenarios/App.framework"
rm -rf "${BASH_SOURCE%/*}/ios/Scenarios/Flutter.framework"
cp -R "$OUTDIR/App.framework" "${BASH_SOURCE%/*}/ios/Scenarios"
cp -R "$DEVICE_TOOLS/../Flutter.framework" "${BASH_SOURCE%/*}/ios/Scenarios"

