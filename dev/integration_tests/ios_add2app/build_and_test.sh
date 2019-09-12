#!/bin/bash

set -e

cd "$(dirname "$0")"

pushd flutterapp
../../../../bin/flutter build ios --debug --simulator --no-codesign
popd

pod install
os_version=$(xcrun --show-sdk-version --sdk iphonesimulator)

PRETTY="cat"
if which xcpretty; then
  PRETTY="xcpretty"
fi

set -o pipefail && xcodebuild \
  -workspace ios_add2app.xcworkspace \
  -scheme ios_add2appTests \
  -sdk "iphonesimulator$os_version" \
  -destination "OS=$os_version,name=iPhone X" test | $PRETTY

