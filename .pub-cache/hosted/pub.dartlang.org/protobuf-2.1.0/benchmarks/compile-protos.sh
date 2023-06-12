#!/bin/bash
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Compile all protos involed in the benchmarking using protoc compiler.

PROTOS=(
  "benchmarks.proto"
  "datasets/google_message1/proto2/benchmark_message1_proto2.proto"
  "datasets/google_message1/proto3/benchmark_message1_proto3.proto"
  "datasets/google_message2/benchmark_message2.proto"
  "datasets/google_message3/benchmark_message3.proto"
  "datasets/google_message3/benchmark_message3_1.proto"
  "datasets/google_message3/benchmark_message3_2.proto"
  "datasets/google_message3/benchmark_message3_3.proto"
  "datasets/google_message3/benchmark_message3_4.proto"
  "datasets/google_message3/benchmark_message3_5.proto"
  "datasets/google_message3/benchmark_message3_6.proto"
  "datasets/google_message3/benchmark_message3_7.proto"
  "datasets/google_message3/benchmark_message3_8.proto"
  "datasets/google_message4/benchmark_message4.proto"
  "datasets/google_message4/benchmark_message4_1.proto"
  "datasets/google_message4/benchmark_message4_2.proto"
  "datasets/google_message4/benchmark_message4_3.proto"
)

SCRIPT_DIR=$(dirname "${BASH_SOURCE}")
OUTPUT_DIR="${SCRIPT_DIR}/temp"

mkdir -p ${OUTPUT_DIR}

set -x

protoc -I"${SCRIPT_DIR}" --dart_out="${OUTPUT_DIR}" "${PROTOS[@]/#/$SCRIPT_DIR/}"
