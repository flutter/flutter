#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

readonly flutter_bin_dir="${FLUTTER_ROOT}/bin"
readonly dart_bin_dir="${flutter_bin_dir}/cache/dart-sdk/bin"

exec "${dart_bin_dir}/dart" "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.dart" "${@:1}"
