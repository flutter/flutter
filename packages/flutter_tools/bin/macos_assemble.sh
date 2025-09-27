#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `xcode_backend.sh` script (used for iOS projects) in the same directory.
#
# -------------------------------------------------------------------------- #

# exit on error, or usage of unset var
set -euo pipefail

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

# Run `dart xcode_backend.dart` with the dart from the Flutter SDK.
# The FLUTTER_ROOT environment variable is required.
if [[ -z "$FLUTTER_ROOT" ]]; then
  echo "error: FLUTTER_ROOT must be set."
  exit 1
fi

DART="$FLUTTER_ROOT/bin/dart"
XCODE_BACKEND_DART="$(dirname "${BASH_SOURCE[0]}")/xcode_backend.dart"

# Main entry point.
if [[ $# == 0 ]]; then
  exec "$DART" "$XCODE_BACKEND_DART" "build" "macos"
else
  exec "$DART" "$XCODE_BACKEND_DART" "$@" "macos"
fi