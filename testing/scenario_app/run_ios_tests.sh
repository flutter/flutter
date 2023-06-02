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

SCENARIO_PATH=$SRC_DIR/out/$FLUTTER_ENGINE/scenario_app/Scenarios
pushd .
cd $SCENARIO_PATH

RESULT_BUNDLE_FOLDER=$(mktemp -d ios_scenario_xcresult_XXX)
RESULT_BUNDLE_PATH="${SCENARIO_PATH}/${RESULT_BUNDLE_FOLDER}"

# Zip and upload xcresult to luci.
# First parameter ($1) is the zip output name.
zip_and_upload_xcresult_to_luci () {
  # We don't want the zip to contain the abusolute path,
  # so use relative path (./$RESULT_BUNDLE_FOLDER) instead.
  zip -q -r $1 "./$RESULT_BUNDLE_FOLDER"
  mv -f $1 $FLUTTER_TEST_OUTPUTS_DIR
  exit 1
}

echo "Running simulator tests with Skia"
echo ""

if set -o pipefail && xcodebuild -sdk iphonesimulator \
  -scheme Scenarios \
  -resultBundlePath "$RESULT_BUNDLE_PATH/ios_scenario.xcresult" \
  -destination 'platform=iOS Simulator,OS=16.2,name=iPhone SE (3rd generation)' \
  clean test \
  FLUTTER_ENGINE="$FLUTTER_ENGINE"; then
  echo "test success."
else
  echo "test failed."
  zip_and_upload_xcresult_to_luci "ios_scenario_xcresult.zip"
fi
rm -rf $RESULT_BUNDLE_PATH

echo "Running simulator tests with Impeller"
echo ""

# Skip testFontRenderingWhenSuppliedWithBogusFont: https://github.com/flutter/flutter/issues/113250
if set -o pipefail && xcodebuild -sdk iphonesimulator \
  -scheme Scenarios \
  -resultBundlePath "$RESULT_BUNDLE_PATH/ios_scenario.xcresult" \
  -destination 'platform=iOS Simulator,OS=16.2,name=iPhone SE (3rd generation)' \
  clean test \
  FLUTTER_ENGINE="$FLUTTER_ENGINE" \
  -skip-testing "ScenariosUITests/BogusFontTextTest/testFontRenderingWhenSuppliedWithBogusFont" \
  INFOPLIST_FILE="Scenarios/Info_Impeller.plist"; then # Plist with FLTEnableImpeller=YES
  echo "test success."
else
  echo "test failed."
  zip_and_upload_xcresult_to_luci "ios_scenario_impeller_xcresult.zip"
fi
rm -rf $RESULT_BUNDLE_PATH

popd
