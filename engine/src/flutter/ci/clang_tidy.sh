#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

# On Mac OS, readlink -f doesn't work, so follow_links traverses the path one
# link at a time, and then cds into the link destination and find out where it
# ends up.
#
# The function is enclosed in a subshell to avoid changing the working directory
# of the caller.
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

SCRIPT_DIR=$(follow_links "$(dirname -- "${BASH_SOURCE[0]}")")
SRC_DIR="$(cd "$SCRIPT_DIR/../.."; pwd -P)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.."; pwd -P)"
DART_BIN="${SRC_DIR}/third_party/dart/tools/sdks/dart-sdk/bin"
DART="${DART_BIN}/dart"

# FLUTTER_LINT_PRINT_FIX will make it so that fix is executed and the generated
# diff is printed to stdout if clang-tidy fails. This is helpful for enabling
# new lints.

# To run on CI, just uncomment the following line:
# FLUTTER_LINT_PRINT_FIX=1

if [[ -z "${FLUTTER_LINT_PRINT_FIX}" ]]; then
  fix_flag=""
else
  fix_flag="--fix --lint-all"
fi

COMPILE_COMMANDS="$SRC_DIR/out/host_debug/compile_commands.json"
if [ ! -f "$COMPILE_COMMANDS" ]; then
  (cd "$SRC_DIR"; ./flutter/tools/gn)
fi

echo "$(date +%T) Running clang_tidy"

cd "$SCRIPT_DIR"
"$DART" \
  --disable-dart-dev \
  "$SRC_DIR/flutter/tools/clang_tidy/bin/main.dart" \
  --src-dir="$SRC_DIR" \
  $fix_flag \
  "$@" && true # errors ignored
clang_tidy_return=$?
if [ $clang_tidy_return -ne 0 ]; then
  if [ -n "$fix_flag" ]; then
    echo "###################################################"
    echo "# Attempted to fix issues with the following patch:"
    echo "###################################################"
    git --no-pager diff
  fi
  exit $clang_tidy_return
fi
