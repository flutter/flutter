#!/bin/bash
set -ex

# Linux Debug
./sky/tools/gn --release
ninja -j 4 -C out/Release
