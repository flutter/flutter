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

"$SCRIPT_DIR/compile_ios_aot.sh" "$1" "$2"

GIT_REVISION="${3:-$(git rev-parse HEAD)}"
BUILD_ID="${4:-$CIRRUS_BUILD_ID}"

(
  cd "${BASH_SOURCE%/*}/ios/Scenarios"
  xcodebuild -project Scenarios.xcodeproj -scheme Scenarios -configuration Debug \
    -sdk iphoneos \
    -derivedDataPath DerivedData/Scenarios \
    build-for-testing
)

(
  cd DerivedData/Scenarios/Build/Products
  zip -r scenarios.zip Debug-iphoneos Scenarios*.xctestrun
  gcloud firebase test ios run --test ./scenarios.zip \
    --device model=iphone8plus,version=12.0,locale=en_US,orientation=portrait \
    --xcode-version=10.2 \
    --results-bucket=gs://flutter_firebase_testlab \
    --results-dir="engine_scenario_test/$GIT_REVISION/$BUILD_ID"
)
