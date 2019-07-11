#!/usr/bin/env bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Generates objc docs for Flutter iOS libraries.

FLUTTER_UMBRELLA_HEADER=$(find ../out -maxdepth 4 -type f -name Flutter.h | grep 'ios_' | head -n 1)
if [[ ! -f "$FLUTTER_UMBRELLA_HEADER" ]]
  then
      echo "Error: This script must be run at the root of the Flutter source tree with at least one built Flutter.framework in ../out/ios*/Flutter.framework."
      exit 1
fi

if [[ $# -eq 0 ]]
  then
      echo "Error: Argument specifying output directory required."
      exit 1
fi

# If GEM_HOME is set, prefer using its copy of jazzy.
# LUCI will put jazzy here instead of on the path.
if [[ -n "${GEM_HOME}" ]]
  then
    PATH="${GEM_HOME}/bin:$PATH"
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
  --xcodebuild-arguments --objc,"$FLUTTER_UMBRELLA_HEADER",--,-x,objective-c,-isysroot,"$(xcrun --show-sdk-path --sdk iphonesimulator)",-I,"$(pwd)"\
  --module Flutter\
  --root-url https://docs.flutter.io/objc/\
  --output "$1"

EXPECTED_CLASSES="FlutterAppDelegate.html
FlutterBasicMessageChannel.html
FlutterCallbackCache.html
FlutterCallbackInformation.html
FlutterDartProject.html
FlutterEngine.html
FlutterError.html
FlutterEventChannel.html
FlutterHeadlessDartRunner.html
FlutterMethodCall.html
FlutterMethodChannel.html
FlutterPluginAppLifeCycleDelegate.html
FlutterStandardMessageCodec.html
FlutterStandardMethodCodec.html
FlutterStandardReader.html
FlutterStandardReaderWriter.html
FlutterStandardTypedData.html
FlutterStandardWriter.html
FlutterViewController.html"

ACTUAL_CLASSES=$(ls "$1/Classes" | sort)

if [[ $EXPECTED_CLASSES != $ACTUAL_CLASSES ]]; then
  echo "Expected classes did not match actual classes"
  echo
  diff <(echo "$EXPECTED_CLASSES") <(echo "$ACTUAL_CLASSES")
  exit -1
fi
