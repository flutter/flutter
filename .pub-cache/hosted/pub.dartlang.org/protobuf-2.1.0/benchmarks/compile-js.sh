#!/bin/sh
# Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Compile benchmark_js to JavaScript using dart2js.

SCRIPT_DIR=$(dirname "${BASH_SOURCE}")
OUTPUT_DIR="${SCRIPT_DIR}/temp"

mkdir -p "${OUTPUT_DIR}"

dart2js -O4                             \
        -o "${OUTPUT_DIR}"/benchmark.js \
        "${SCRIPT_DIR}"/benchmark_js.dart
