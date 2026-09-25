#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Pre-commit guard hook to enforce PR chain consistency, formatting, static analysis,
# clang-tidy, gn check, Android SDK lint, and RFC 410 invariants.
set -e

FLUTTER_ROOT="/usr/local/google/home/boetger/src/flutter"
DART_BIN="$FLUTTER_ROOT/bin/dart"

if [ ! -x "$DART_BIN" ]; then
  DART_BIN="dart"
fi

# Ensure engine tool (et) and depot_tools (vpython3/gn) are in PATH
export PATH="$FLUTTER_ROOT/engine/src/flutter/bin:$FLUTTER_ROOT/bin:/usr/local/google/home/boetger/src/depot_tools:$PATH"

CURRENT_BRANCH=$(git -C "$FLUTTER_ROOT" branch --show-current 2>/dev/null || echo "")

# Enforce strict chain checks and parallel linters/analyzers on migration branches
if [[ "$CURRENT_BRANCH" == android-embedder-migration-v10/* ]]; then
  HEAD_SHA=$(git -C "$FLUTTER_ROOT" rev-parse HEAD 2>/dev/null || echo "none")
  INDEX_TREE_SHA=$(git -C "$FLUTTER_ROOT" write-tree 2>/dev/null || echo "none")
  STATE_KEY="${CURRENT_BRANCH}:${HEAD_SHA}:${INDEX_TREE_SHA}"
  STAMP_FILE="/tmp/flutter_pre_commit_verified_state"

  if [[ "$1" != "--force" ]] && [[ -f "$STAMP_FILE" ]] && [[ "$(cat "$STAMP_FILE")" == "$STATE_KEY" ]]; then
    echo "==> [Pre-Commit Guard] Staged tree ($INDEX_TREE_SHA) already verified."
    exit 0
  fi

  LINTER_SCRIPT="$FLUTTER_ROOT/.agents/skills/pr-chain-manager/scripts/pre_commit_linter.dart"
  if [ -f "$LINTER_SCRIPT" ]; then
    "$DART_BIN" "$LINTER_SCRIPT" "$@"
    echo "$STATE_KEY" > "$STAMP_FILE"
  fi
fi

exit 0
