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

xcrun xcodebuild \
  -workspace ios_add2app.xcworkspace \
  -scheme ios_add2app \
  -sdk "iphonesimulator" \
  -destination "OS=latest,name=iPhone 12" test
