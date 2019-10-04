#!/bin/bash
set -ex

PATH="$HOME/depot_tools:$PATH"
cd ..

# Build the flutter runner tests far directory
flutter/tools/gn --fuchsia --no-lto --runtime-mode debug
ninja -C out/fuchsia_debug_x64 flutter/shell/platform/fuchsia/flutter:flutter_runner_tests

# Generate the far package
flutter/tools/fuchsia/gen_package.py\
  --pm-bin $PWD/fuchsia/sdk/linux/tools/pm\
  --package-dir $PWD/out/fuchsia_debug_x64/flutter_runner_tests_far\
  --signing-key $PWD/flutter/tools/fuchsia/development.key\
  --far-name flutter_runner_tests

