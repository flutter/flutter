#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# //flutter/dev/tools/lib/proto
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DARTFMT="$DIR/../../../../bin/cache/dart-sdk/bin/dartfmt"

# Ensure dart-sdk is cached
"$DIR/../../../../bin/dart" --version

if ! type protoc >/dev/null 2>&1; then
  PROTOC_LINK='https://grpc.io/docs/protoc-installation/'
  echo "Error! \"protoc\" binary required on path."
  echo "See $PROTOC_LINK for more information."
  exit 1
fi

if ! type dart >/dev/null 2>&1; then
  echo "Error! \"dart\" binary required on path."
  exit 1
fi

# Use null-safe protoc_plugin
dart pub global activate protoc_plugin 20.0.0

protoc --dart_out="$DIR" --proto_path="$DIR" "$DIR/conductor_state.proto"

for SOURCE_FILE in $(ls "$DIR"/*.pb*.dart); do
  # Format in place file
  "$DARTFMT" --overwrite --line-length 120 "$SOURCE_FILE"

  # Create temp copy with the license header prepended
  cp "$DIR/license_header.txt" "${SOURCE_FILE}.tmp"

  # Add an extra newline required by analysis (analysis also prevents
  # license_header.txt from having the trailing newline)
  echo '' >> "${SOURCE_FILE}.tmp"

  cat "$SOURCE_FILE" >> "${SOURCE_FILE}.tmp"

  # Move temp version (with license) over the original
  mv "${SOURCE_FILE}.tmp" "$SOURCE_FILE"
done
