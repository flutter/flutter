#!/bin/sh

set -e

TESTING_DIR=$(dirname "$0")
pushd $TESTING_DIR

FLUTTER_ENGINE=ios_debug_sim_unopt

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

cd ../../../..

if [ ! -d "out/$FLUTTER_ENGINE" ]; then
  echo "You must GN to generate out/$FLUTTER_ENGINE"
  echo "example: ./flutter/tools/gn --ios --simulator --unoptimized"
  exit 1
fi

autoninja -C out/$FLUTTER_ENGINE ios_test_flutter
popd
$TESTING_DIR/run_tests.sh $FLUTTER_ENGINE
