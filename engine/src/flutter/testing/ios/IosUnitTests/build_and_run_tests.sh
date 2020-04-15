#!/bin/sh

set -e

FLUTTER_ENGINE=ios_debug_sim_unopt

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

pushd $PWD
cd ../../../..

if [ ! -d "out/$FLUTTER_ENGINE" ]; then
  echo "You must GN to generate out/$FLUTTER_ENGINE"
  echo "example: ./flutter/tools/gn --ios --simulator --unoptimized"
  exit 1
fi

autoninja -C out/$FLUTTER_ENGINE ios_test_flutter
popd
./run_tests.sh $FLUTTER_ENGINE
