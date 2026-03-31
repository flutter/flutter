#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `macos_assemble.sh` script (used for macOS projects) in the same directory.
#
# -------------------------------------------------------------------------- #

# exit on error, or usage of unset var
set -euo pipefail

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

function follow_links() (
  cd -P -- "$(dirname -- "$1")"
  file="$PWD/$(basename -- "$1")"
  while [[ -h "$file" ]]; do
    cd -P -- "$(dirname -- "$file")"
    file="$(readlink -- "$file")"
    cd -P -- "$(dirname -- "$file")"
    file="$PWD/$(basename -- "$file")"
  done
  echo "$file"
)

PROG_NAME="$(follow_links "${BASH_SOURCE[0]}")"
BIN_DIR="$(cd "${PROG_NAME%/*}" ; pwd -P)"
FLUTTER_ROOT="$BIN_DIR/../../.."
DART="$FLUTTER_ROOT/bin/dart"

# Xcode provides its own version of Git that may be incompatible with the
# primary installation of Git on the host.  If another Git is found when all
# Xcode directories are removed from the PATH, then tell Flutter's scripts to
# use that version of Git.
NO_XCODE_PATH=$(echo $PATH | tr ":" "\n" | grep -v /Xcode.app/ | tr "\n" ":")
if NO_XCODE_GIT=$(env PATH=$NO_XCODE_PATH which git); then
  export FLUTTER_GIT=$NO_XCODE_GIT
fi

"$DART" "$BIN_DIR/xcode_backend.dart" "$@" "ios"
