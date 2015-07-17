#!/bin/bash
set -ex

# Linux Debug
./sky/tools/gn --debug
ninja -j 8 -C out/Debug
./sky/tools/test_sky --debug
