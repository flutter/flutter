#!/bin/bash
set -ex

# Linux Debug
./sky/tools/gn --debug
ninja -j 1 -C out/Debug
