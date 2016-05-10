#!/bin/bash
set -ex

PATH="$HOME/depot_tools:$PATH"

sky/tools/gn --unoptimized
ninja -C out/host_debug_unopt generate_dart_ui
travis/analyze.sh
