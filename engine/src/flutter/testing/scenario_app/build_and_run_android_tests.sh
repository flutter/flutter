#!/bin/sh
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs the Android scenario tests on a connected device.
# TODO(https://github.com/flutter/flutter/issues/55326): use Flutter tool and
# just build debug JIT for emulator.

set -e

FLUTTER_ENGINE=android_profile_unopt_arm64

if [ $# -eq 1 ]; then
  FLUTTER_ENGINE=$1
fi

cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd

pushd ../../..

if [ ! -d "out/$FLUTTER_ENGINE" ]; then
  echo "You must GN to generate out/$FLUTTER_ENGINE and its host engine."
  echo "Example: "
  echo "  ./tools/gn --android --unoptimized --android-cpu arm64 --runtime-mode profile"
  echo "  ./tools/gn --unoptimized --runtime-mode profile"
  echo "to create out/android_profile_unopt_arm64 and out/host_profile_unopt."
  exit 1
fi

autoninja -C out/$FLUTTER_ENGINE

popd

./compile_android_aot.sh ../../../out/host_profile_unopt ../../../out/$FLUTTER_ENGINE/clang_x64

./run_android_tests.sh $FLUTTER_ENGINE
