#!/bin/bash
set -ex

./sky/tools/gn --release
ninja -j 4 -C out/Release
./sky/tools/skyanalyzer --congratulate ../../../examples/stocks/lib/main.dart
