#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script is expected to run from $ENGINE_PATH/src/out/host_release/
# it is currently used only by automation to collect and upload metrics.

set -ex

./txt_benchmarks --benchmark_format=json > txt_benchmarks.json
./fml_benchmarks --benchmark_format=json > fml_benchmarks.json
./shell_benchmarks --benchmark_format=json > shell_benchmarks.json
./ui_benchmarks --benchmark_format=json > ui_benchmarks.json

