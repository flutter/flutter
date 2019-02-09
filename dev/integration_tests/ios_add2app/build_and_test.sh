#!/bin/bash

set -e

cd "$(dirname "$0")"

pushd flutterapp
../../../../bin/flutter build ios --debug --no-codesign -v
popd

pod install
os_version=$(xcrun --show-sdk-version --sdk iphonesimulator)
xcodebuild -workspace ios_add2app.xcworkspace -scheme ios_add2appTests -sdk "iphonesimulator$os_version" -destination "OS=$os_version,name=iPhone X" test