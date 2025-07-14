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

function follow_links() (
  cd -P "$(dirname -- "$1")"
  file="$PWD/$(basename -- "$1")"
  while [[ -h "$file" ]]; do
    cd -P "$(dirname -- "$file")"
    file="$(readlink -- "$file")"
    cd -P "$(dirname -- "$file")"
    file="$PWD/$(basename -- "$file")"
  done
  echo "$file"
)

PROG_NAME="$(follow_links "${BASH_SOURCE[0]}")"
BIN_DIR="$(cd "${PROG_NAME%/*}" ; pwd -P)"
FLUTTER_ROOT="$BIN_DIR/../../.."
DART="$FLUTTER_ROOT/bin/dart"

# Main entry point.
if [[ $# == 0 ]]; then
  "$DART" "$BIN_DIR/xcode_backend.dart" "build" "macos"
else
  "$DART" "$BIN_DIR/xcode_backend.dart" "$@" "macos"
fi
