#!/bin/bash
set -ex

PATH="$HOME/depot_tools:$PATH"

cd ..

# Build the dart UI files
flutter/tools/gn --unoptimized
ninja -C out/host_debug_unopt generate_dart_ui

# Analyze the dart UI
flutter/ci/analyze.sh
flutter/ci/licenses.sh
