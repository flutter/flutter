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

readonly DEVICE_NAME="iPhone SE (3rd generation)"
readonly DEVICE=com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation
readonly OS_RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-17-0
readonly OS="17.0"

# Delete any existing devices named "iPhone SE (3rd generation)". Having more
# than one may cause issues when builds target the device.
echo "Deleting any existing devices names $DEVICE_NAME..."
RESULT=0
while [[ $RESULT == 0 ]]; do
    xcrun simctl delete "$DEVICE_NAME" || RESULT=1
    if [ $RESULT == 0 ]; then
        echo "Deleted $DEVICE_NAME"
    fi
done
echo ""

echo "Creating $DEVICE_NAME $DEVICE $OS_RUNTIME ..."
xcrun simctl create "$DEVICE_NAME" "$DEVICE" "$OS_RUNTIME"
echo ""

echo "Running simulator tests with Skia"
echo ""

if set -o pipefail && xcodebuild -sdk iphonesimulator \
  -scheme Scenarios \
  -resultBundlePath "$RESULT_BUNDLE_PATH/ios_scenario.xcresult" \
  -destination "platform=iOS Simulator,OS=$OS,name=$DEVICE_NAME" \
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
# Skip golden tests that use software rendering: https://github.com/flutter/flutter/issues/131888
if set -o pipefail && xcodebuild -sdk iphonesimulator \
  -scheme Scenarios \
  -resultBundlePath "$RESULT_BUNDLE_PATH/ios_scenario.xcresult" \
  -destination "platform=iOS Simulator,OS=$OS,name=$DEVICE_NAME" \
  clean test \
  FLUTTER_ENGINE="$FLUTTER_ENGINE" \
  -skip-testing ScenariosUITests/MultiplePlatformViewsBackgroundForegroundTest/testPlatformView \
  -skip-testing ScenariosUITests/MultiplePlatformViewsTest/testPlatformView \
  -skip-testing ScenariosUITests/NonFullScreenFlutterViewPlatformViewUITests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationClipPathTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationClipPathWithTransformTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationClipRectAfterMovedTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationClipRectTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationClipRectWithTransformTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationClipRRectTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationClipRRectWithTransformTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationLargeClipRRectTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationLargeClipRRectWithTransformTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationOpacityTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewMutationTransformTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewRotation/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewUITests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewWithNegativeOtherBackDropFilterTests/testPlatformView \
  -skip-testing ScenariosUITests/PlatformViewWithOtherBackdropFilterTests/testPlatformView \
  -skip-testing ScenariosUITests/RenderingSelectionTest/testSoftwareRendering \
  -skip-testing ScenariosUITests/TwoPlatformViewClipPathTests/testPlatformView \
  -skip-testing ScenariosUITests/TwoPlatformViewClipRectTests/testPlatformView \
  -skip-testing ScenariosUITests/TwoPlatformViewClipRRectTests/testPlatformView \
  -skip-testing ScenariosUITests/TwoPlatformViewsWithOtherBackDropFilterTests/testPlatformView \
  -skip-testing ScenariosUITests/UnobstructedPlatformViewTests/testMultiplePlatformViewsWithOverlays \
  # Plist with FLTEnableImpeller=YES, all projects in the workspace requires this file.
  # For example, FlutterAppExtensionTestHost has a dummy file under the below directory.
  INFOPLIST_FILE="Scenarios/Info_Impeller.plist"; then
  echo "test success."
else
  echo "test failed."
  zip_and_upload_xcresult_to_luci "ios_scenario_impeller_xcresult.zip"
fi
rm -rf $RESULT_BUNDLE_PATH

popd
