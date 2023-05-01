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

if uname -m | grep "arm64"; then
  FLUTTER_ENGINE="ios_debug_sim_unopt_arm64"
else
  FLUTTER_ENGINE="ios_debug_sim_unopt"
fi

if [[ $# -eq 1 ]]; then
  FLUTTER_ENGINE="$1"
fi

# Make sure simulators rotate automatically for "PlatformViewRotation" test.
# Can also be set via Simulator app Device > Rotate Device Automatically
defaults write com.apple.iphonesimulator RotateWindowWhenSignaledByGuest -int 1

cd $SRC_DIR/out/$FLUTTER_ENGINE/scenario_app/Scenarios

echo "Running simulator tests with Skia"
echo ""

set -o pipefail && xcodebuild -sdk iphonesimulator \
  -scheme Scenarios \
  -destination 'platform=iOS Simulator,OS=16.2,name=iPhone SE (3rd generation)' \
  clean test \
  FLUTTER_ENGINE="$FLUTTER_ENGINE"

echo "Running simulator tests with Impeller"
echo ""

# Skip testFontRenderingWhenSuppliedWithBogusFont: https://github.com/flutter/flutter/issues/113250
set -o pipefail && xcodebuild -sdk iphonesimulator \
  -scheme Scenarios \
  -destination 'platform=iOS Simulator,OS=16.2,name=iPhone SE (3rd generation)' \
  clean test \
  FLUTTER_ENGINE="$FLUTTER_ENGINE" \
  -skip-testing "ScenariosUITests/BogusFontTextTest/testFontRenderingWhenSuppliedWithBogusFont" \
  INFOPLIST_FILE="Scenarios/Info_Impeller.plist" # Plist with FLTEnableImpeller=YES
