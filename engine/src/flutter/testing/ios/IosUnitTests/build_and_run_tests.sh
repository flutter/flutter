#!/bin/sh
pushd $PWD
cd ../../../..
./flutter/tools/gn --ios --simulator --unoptimized
ninja -j 100 -C out/ios_debug_sim_unopt
popd
./run_tests.sh ios_debug_sim_unopt
