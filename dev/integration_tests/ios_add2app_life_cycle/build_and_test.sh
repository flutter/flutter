#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

cd "$(dirname "$0")"

pushd flutterapp
../../../../bin/flutter build ios --debug --simulator --no-codesign
popd

pod install
os_version=$(xcrun --show-sdk-version --sdk iphonesimulator)


xcodebuild \
  -workspace ios_add2app.xcworkspace \
  -scheme ios_add2app \
  -sdk "iphonesimulator$os_version" \
  -destination "OS=$os_version,name=iPhone X" test
