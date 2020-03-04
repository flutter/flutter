#!/bin/sh

set -e

FLUTTER_ENGINE=ios_debug_sim_unopt

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

PRETTY="cat"
if which xcpretty; then
  PRETTY="xcpretty"
fi

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

pushd ios/Scenarios

set -o pipefail && xcodebuild -sdk iphonesimulator \
  -scheme Scenarios \
  -destination 'platform=iOS Simulator,OS=13.0,name=iPhone 8' \
  test \
  FLUTTER_ENGINE=$FLUTTER_ENGINE | $PRETTY

popd
