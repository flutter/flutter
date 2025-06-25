#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -o pipefail -e;

BUILD_VARIANT="${1:-host_debug_unopt}"
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

python3 "${CURRENT_DIR}/run_tests.py" --variant="${BUILD_VARIANT}" --type=engine,dart,benchmarks

# This does not run the web_ui tests. To run those, use:
#   lib/web_ui/dev/felt test
