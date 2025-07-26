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
# bin/internal/content_aware_hash.ps1: script for calculating the hash on windows
# bin/internal/content_aware_hash.sh: script for calculating the hash on mac/linux
# .github/workflows/content-aware-hash.yml: github action for CI/CD hashing
TRACKEDFILES="DEPS engine bin/internal/release-candidate-branch.version"
BASEREF="HEAD"

set +e
# We will fallback to origin/master if upstream is not detected.
git -C "$FLUTTER_ROOT" remote get-url upstream >/dev/null 2>&1
exit_code=$?
set -e
if [[ $exit_code -eq 0 ]]; then
  MERGEBASE=$(git -C "$FLUTTER_ROOT" merge-base HEAD upstream/master)
else
  MERGEBASE=$(git -C "$FLUTTER_ROOT" merge-base HEAD origin/master)
fi

# Check to see if we're in a local development branch and the branch has any
# changes to engine code - including non-committed changes.
if [ "$(git -C "$FLUTTER_ROOT" rev-parse --abbrev-ref HEAD)" != "master" ] && \
    ! git -C "$FLUTTER_ROOT" diff --quiet "$MERGEBASE" -- $TRACKEDFILES; then
  BASEREF="$MERGEBASE"
fi
git -C "$FLUTTER_ROOT" ls-tree --format "%(objectname) %(path)" $BASEREF -- $TRACKEDFILES | git hash-object --stdin
