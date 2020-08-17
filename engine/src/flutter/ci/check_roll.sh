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
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.."; pwd -P)"

cd "$FLUTTER_DIR"

if git remote get-url upstream >/dev/null 2>&1; then
  UPSTREAM=upstream/master
else
  UPSTREAM=master
fi;

FLUTTER_VERSION="$(curl -s https://raw.githubusercontent.com/flutter/flutter/master/bin/internal/engine.version)"
BEHIND="$(git rev-list "$FLUTTER_VERSION".."$UPSTREAM" --oneline | wc -l)"
MAX_BEHIND=16 # no more than 4 bisections to identify the issue

if [[ $BEHIND -le $MAX_BEHIND ]]; then
  echo "OK, the flutter/engine to flutter/flutter roll is only $BEHIND commits behind."
else
  echo "ERROR: The flutter/engine to flutter/flutter roll is $BEHIND commits behind!"
  echo "       It exceeds our max allowance of $MAX_BEHIND. Unless that this commit fixes the roll,"
  echo "       please roll engine into flutter first before merging more commits into engine."
  exit 1
fi
