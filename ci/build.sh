#!/bin/bash
set -ex

PATH="$HOME/depot_tools:$PATH"
cd ..

PATH=$(pwd)/third_party/dart/tools/sdks/dart-sdk/bin:$PATH

# Build the dart UI files
flutter/tools/gn --unoptimized
ninja -C out/host_debug_unopt generate_dart_ui

# Analyze the dart UI
flutter/ci/analyze.sh
flutter/ci/licenses.sh

# Check that dart libraries conform
cd flutter/web_sdk
pub get
cd ..
# TODO(jsimmons): reenable this when the analyzer has been updated for Dart 2.10
# dart web_sdk/test/api_conform_test.dart
