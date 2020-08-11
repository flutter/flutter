#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

FLUTTER_ENGINE=android_debug_unopt_x64

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

pushd ../../..

if [ ! -d "out/$FLUTTER_ENGINE" ]; then
  echo "You must GN to generate out/$FLUTTER_ENGINE and its host engine."
  echo "Example: "
  echo "  ./tools/gn --android --unoptimized --android-cpu x64 --runtime-mode debug"
  echo "  ./tools/gn --unoptimized --runtime-mode debug"
  echo "to create out/android_debug_unopt_x64 and out/host_debug_unopt."
  exit 1
fi

autoninja -C out/$FLUTTER_ENGINE

popd

./compile_android_jit.sh ../../../out/host_debug_unopt ../../../out/$FLUTTER_ENGINE/clang_x64

./run_android_tests.sh $FLUTTER_ENGINE
