#!/usr/bin/env bash

# //flutter/dev/tools/lib/proto
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DARTFMT="$DIR/../../../../bin/cache/dart-sdk/bin/dartfmt"

# Ensure dart-sdk is cached
"$DIR/../../../../bin/dart" --version >/dev/null 2>&1

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

# Pin protoc-gen-dart to pre-nullsafe version.
dart pub global activate protoc_plugin 19.3.1

protoc --dart_out="$DIR" --proto_path="$DIR" "$DIR/conductor_state.proto"

for SOURCE_FILE in $(ls "$DIR"/*.pb*.dart); do
  "$DARTFMT" --overwrite --line-length 120 "$SOURCE_FILE"
done
