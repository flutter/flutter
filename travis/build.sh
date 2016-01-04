#!/bin/bash
set -ex

PATH="$HOME/depot_tools:$PATH"

sky/tools/gn --debug
ninja -C out/Debug generate_dart_ui
travis/analyze.sh
