#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `content_aware_hash.ps1` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# -------------------------------------------------------------------------- #

set -e

FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

unset GIT_DIR
unset GIT_INDEX_FILE
unset GIT_WORK_TREE

# Cannot use '*' for files in this command
# DEPS: tracks third party dependencies related to building the engine
# engine: all the code in the engine folder
# bin/internal/release-candidate-branch.version: release marker
TRACKEDFILES=(DEPS engine bin/internal/release-candidate-branch.version)
BASEREF="${1:-HEAD}"

# Workaround for Xcode's git multi-pack-index incompatibility.
# https://github.com/flutter/flutter/issues/184376
GIT_OPTS=()
if [[ "$(git --version)" == *"Apple Git"* ]]; then
  GIT_OPTS=(-c core.multiPackIndex=false)
fi
if ! HASH=$(set -o pipefail; git "${GIT_OPTS[@]}" -C "$FLUTTER_ROOT" ls-tree "$BASEREF" -- "${TRACKEDFILES[@]}" | git hash-object --stdin); then
  >&2 echo "${0}: git error when generating Flutter content-aware hash"
  exit 1
fi
echo "$HASH"
