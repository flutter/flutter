#!/usr/bin/env bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ----------------------------------
#
# Please keep the logic in this file consistent with the logic in the
# `yapf.bat` script in the same directory to ensure that it continues to
# work across all platforms!
#
# --------------------------------------------------------------------------

# Generates objc docs for Flutter iOS libraries.

set -e

# On Mac OS, readlink -f doesn't work, so follow_links traverses the path one
# link at a time, and then cds into the link destination and find out where it
# ends up.
#
# The function is enclosed in a subshell to avoid changing the working directory
# of the caller.
function follow_links() (
  cd -P "$(dirname -- "$1")"
  file="$PWD/$(basename -- "$1")"
  while [[ -L "$file" ]]; do
    cd -P "$(dirname -- "$file")"
    file="$(readlink -- "$file")"
    cd -P "$(dirname -- "$file")"
    file="$PWD/$(basename -- "$file")"
  done
  echo "$file"
)

SCRIPT_DIR=$(follow_links "$(dirname -- "${BASH_SOURCE[0]}")")
SRC_DIR="$(
  cd "$SCRIPT_DIR/../.."
  pwd -P
)"
YAPF_DIR="$(
  cd "$SRC_DIR/flutter/third_party/yapf"
  pwd -P
)"

has_lib2to3_check_script="
import sys
version = sys.version_info
try:
    __import__('lib2to3')
    print(f'Python3 version {version.major}.{version.minor} has '
          f'the lib2to3 import.')
except ImportError:
    print(f'Python3 version {version.major}.{version.minor} does not have '
          f'the lib2to3 import.',
          file=sys.stderr)
    sys.exit(1)
"

# TODO: https://github.com/flutter/flutter/issues/158384
# Migrate to a supported Python formatter.
if command -v python3.10 &>/dev/null && (python3.10 -c "$has_lib2to3_check_script" || exit 1); then
  PYTHON_EXEC="python3.10"
elif command -v python3.11 &>/dev/null && (python3.11 -c "$has_lib2to3_check_script" || exit 1); then
  PYTHON_EXEC="python3.11"
elif command -v python3.12 &>/dev/null && (python3.12 -c "$has_lib2to3_check_script" || exit 1); then
  PYTHON_EXEC="python3.12"
else
  python3 -c "
import sys
version = sys.version_info
if (version.major, version.minor) > (3, 12):
    print(f'Error: The yapf Python formatter requires Python version 3.12 or '
          f'earlier. The installed python3 version is '
          f'{version.major}.{version.minor}.',
          file=sys.stderr)
    sys.exit(1)
else:
    print(f'Using python3 version {version.major}.{version.minor}.')
" || exit 1
  PYTHON_EXEC="python3"
fi

PYTHONPATH="$YAPF_DIR" $PYTHON_EXEC "$YAPF_DIR/yapf" "$@"
