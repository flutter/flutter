#!/bin/bash

set -e

cd "$(dirname "$0")"

pushd flutterapp
../../../../bin/flutter build ios --debug --no-codesign -v

pushd .ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -destination generic/platform=iOS -configuration Debug CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY="" CODE_SIGNING_ALLOWED=NO
xcodebuild -workspace Runner.xcworkspace -scheme Runner -destination generic/platform=iOS -configuration Profile CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY="" CODE_SIGNING_ALLOWED=NO
xcodebuild -workspace Runner.xcworkspace -scheme Runner -destination generic/platform=iOS -configuration Release CODE_SIGNING_REQUIRED=NO CODE_SIGNING_IDENTITY="" CODE_SIGNING_ALLOWED=NO
popd
popd

pod install
os_version=$(xcrun --show-sdk-version --sdk iphonesimulator)
xcodebuild -workspace ios_add2app.xcworkspace -scheme ios_add2appTests -sdk "iphonesimulator$os_version" -destination "OS=$os_version,name=iPhone X" test