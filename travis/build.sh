#!/bin/bash
set -ex

# Linux Debug
./sky/tools/gn --release
ninja -j 2 -C out/Release
