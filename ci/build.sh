#!/bin/bash
set -ex

PATH="$HOME/depot_tools:$PATH"

cd ..

flutter/tools/gn --unoptimized
ninja -C out/host_debug_unopt generate_dart_ui
flutter/ci/analyze.sh
flutter/ci/licenses.sh
