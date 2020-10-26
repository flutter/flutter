#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script is expected to run from $ENGINE_PATH/src/flutter/testing/benchmark
# it is currently used only by automation to collect and upload metrics.

set -ex

pub get
dart bin/parse_and_send.dart ../../../out/host_release/txt_benchmarks.json
dart bin/parse_and_send.dart ../../../out/host_release/fml_benchmarks.json
dart bin/parse_and_send.dart ../../../out/host_release/shell_benchmarks.json
dart bin/parse_and_send.dart ../../../out/host_release/ui_benchmarks.json
