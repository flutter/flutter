#!/bin/sh
FLUTTER_ENGINE=ios_debug_sim_unopt

TESTING_DIR=$(dirname "$0")
pushd $TESTING_DIR

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

../../run_tests.py --variant $FLUTTER_ENGINE --type objc --ios-variant $FLUTTER_ENGINE

popd
