#!/bin/bash
set -ex

./sky/tools/gn --debug
ninja -j 8 -C out/Debug
