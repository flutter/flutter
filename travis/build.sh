#!/bin/bash
set -ex

./sky/tools/gn --release
ninja -j 4 -C out/Release
./sky/tools/run_tests --release -j 1
