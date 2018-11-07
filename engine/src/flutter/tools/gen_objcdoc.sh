#!/usr/bin/env bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Generates objc docs for Flutter iOS libraries.

if [ ! -d "shell/platform/darwin/ios" ]
  then
      echo "Error: This script must be run at the root of the Flutter source tree."
      exit 1
fi

if [ $# -eq 0 ]
  then
      echo "Error: Argument specifying output directory required."
      exit 1
fi

# Use iPhoneSimulator SDK
# See: https://github.com/realm/jazzy/issues/791
jazzy \
  --objc\
  --sdk iphonesimulator\
  --clean\
  --author Flutter Team\
  --author_url 'https://flutter.io'\
  --github_url 'https://github.com/flutter'\
  --github-file-prefix 'http://github.com/flutter/engine/blob/master'\
  --module-version 1.0.0\
  --xcodebuild-arguments --objc,shell/platform/darwin/ios/framework/Headers/Flutter.h,--,-x,objective-c,-isysroot,$(xcrun --show-sdk-path --sdk iphonesimulator),-I,$(pwd)\
  --module Flutter\
  --root-url https://docs.flutter.io/objc/\
  --output $1\
  --no-download-badge
