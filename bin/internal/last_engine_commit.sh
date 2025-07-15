#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Based on the current repository state, writes on stdout the last commit in the
# git tree that edited either `DEPS` or any file in the `engine/` sub-folder,
# which is used to ensure `bin/internal/engine.version` is set correctly.
#

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `last_engine_commit.ps1` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# https://github.com/flutter/flutter/blob/main/docs/tool/Engine-artifacts.md.
#
# Want to test this script?
# $ cd dev/tools
# $ dart test test/last_engine_commit_test.dart
#
# -------------------------------------------------------------------------- #

set -e

FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

# 1. Determine when we diverged from master, and prevent set -e from exiting.
MERGE_BASE_COMMIT="$(git merge-base HEAD master || echo "")"

# If we did not find a merge-base, fail
if [[ -z "$MERGE_BASE_COMMIT" ]]; then
  echo >&2 "Error: Could not determine a suitable engine commit."
  echo >&2 "Current branch: $(git rev-parse --abbrev-ref HEAD)"
  echo >&2 "Expected a different branch, from master"
  exit 1
fi

# 2. Define and search history range to searhc within (unique to changes on this branch).
HISTORY_RANGE="$MERGE_BASE_COMMIT..HEAD"
ENGINE_COMMIT="$(git log -1 --pretty=format:%H --ancestry-path "$HISTORY_RANGE" -- "$(git rev-parse --show-toplevel)/DEPS" "$(git rev-parse --show-toplevel)/engine")"

# 3. If no engine-related commit was found within the current branch's history, fallback to the first commit on this branch.
if [[ -z "$ENGINE_COMMIT" ]]; then
  # Find the oldest commit on HEAD that is *not* reachable from MERGE_BASE_COMMIT.
  # This is the first commit *on this branch* after it diverged from 'master'.
  ENGINE_COMMIT="$(git log --pretty=format:%H --reverse --ancestry-path "$MERGE_BASE_COMMIT"..HEAD | head -n 1)"

  # Final check: If even this fallback fails (which would be highly unusual if MERGE_BASE_COMMIT was found),
  # then something is truly wrong.
  if [[ -z "$ENGINE_COMMIT" ]]; then
    echo >&2 "Error: Unexpected state. MERGE_BASE_COMMIT was found ($MERGE_BASE_COMMIT), but no commits found on current branch after it."
    echo >&2 "Current branch: $(git rev-parse --abbrev-ref HEAD)"
    echo >&2 "History range searched for fallback: $HISTORY_RANGE"
    echo >&2 "All commits on current branch (for debug):"
    git log --pretty=format:%H
    exit 1
  fi
fi

echo "$ENGINE_COMMIT"
