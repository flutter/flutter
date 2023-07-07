#!/bin/bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fast fail the script on failures.
set -e

# This script checks to make sure that each of the plugins *could* be published.
# It doesn't actually publish anything.

unset CDPATH

# So that developers can run this script from anywhere and it will work as
# expected.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

function format() {
  (cd "$REPO_DIR" && dart format --set-exit-if-changed --line-length=100 "$@" lib test ci example)
}

# Make sure dartfmt is run on everything
function check_format() {
  echo "Checking dart format..."
  local needs_dart_format
  needs_dart_format="$(format --output=none "$@")"
  if [[ $? != 0 ]]; then
    echo "FAILED"
    echo "$needs_dart_format"
    echo ""
    echo "Fix formatting with: ci/format.sh"
    exit 1
  fi
  echo "PASSED"
}

function fix_formatting() {
  echo "Fixing formatting..."
  format --output=write "$@"
}

if [[ "$1" == "--check" ]]; then
  shift
  check_format "$@"
else
  fix_formatting "$@"
fi
