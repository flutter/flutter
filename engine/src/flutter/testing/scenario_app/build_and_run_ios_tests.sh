#!/bin/sh
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

FLUTTER_ENGINE=ios_debug_sim_unopt

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

pushd ../../..

if [ ! -d "out/$FLUTTER_ENGINE" ]; then
  echo "You must GN to generate out/$FLUTTER_ENGINE"
  echo "Example: "
  echo "  ./flutter/tools/gn --ios --simulator --unoptimized"
  echo "  ./flutter/tools/gn --unoptimized"
  echo "to create out/ios_debug_sim_unopt and out/host_debug_unopt."
  exit 1
fi

autoninja -C out/$FLUTTER_ENGINE

popd

./compile_ios_jit.sh ../../../out/host_debug_unopt ../../../out/$FLUTTER_ENGINE/clang_x64

./run_ios_tests.sh $FLUTTER_ENGINE
