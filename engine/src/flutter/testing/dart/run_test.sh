#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

FILE=$1
COMPILE_TARGET=compile_$FILE.dart
DART_FILTER=$FILE.dart

ninja -C ../out/host_debug_unopt_arm64 $COMPILE_TARGET
./testing/run_tests.py --type=dart --dart-filter=$DART_FILTER --variant=host_debug_unopt_arm64
