#!/bin/sh
FLUTTER_ENGINE=ios_debug_sim_unopt

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

PRETTY="cat"
if which xcpretty; then
  PRETTY="xcpretty"
fi

set -o pipefail && xcodebuild -sdk iphonesimulator \
  -scheme IosUnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 8,OS=13.0' \
  test \
  FLUTTER_ENGINE=$FLUTTER_ENGINE | $PRETTY
