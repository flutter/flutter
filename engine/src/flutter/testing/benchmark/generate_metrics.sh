#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script expects $ENGINE_PATH to be set. It is currently used only
# by automation to collect and upload metrics.

set -ex

$ENGINE_PATH/src/out/host_release/txt_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/txt_benchmarks.json
$ENGINE_PATH/src/out/host_release/fml_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/fml_benchmarks.json
$ENGINE_PATH/src/out/host_release/shell_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/shell_benchmarks.json
$ENGINE_PATH/src/out/host_release/ui_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/ui_benchmarks.json
$ENGINE_PATH/src/out/host_release/display_list_builder_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/display_list_builder_benchmarks.json
$ENGINE_PATH/src/out/host_release/display_list_region_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/display_list_region_benchmarks.json
$ENGINE_PATH/src/out/host_release/display_list_transform_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/display_list_transform_benchmarks.json
$ENGINE_PATH/src/out/host_release/geometry_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/geometry_benchmarks.json
$ENGINE_PATH/src/out/host_release/canvas_benchmarks --benchmark_format=json > $ENGINE_PATH/src/out/host_release/canvas_benchmarks.json
