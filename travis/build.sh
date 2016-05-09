#!/bin/bash
set -ex

PATH="$HOME/depot_tools:$PATH"

sky/tools/gn --debug
ninja -C out/host_develop_debug generate_dart_ui
travis/analyze.sh
