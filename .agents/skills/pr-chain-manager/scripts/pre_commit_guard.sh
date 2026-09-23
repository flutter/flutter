#!/bin/bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Pre-commit guard hook to enforce PR chain consistency and linting.
set -e

FLUTTER_ROOT="/usr/local/google/home/boetger/src/flutter"
DART_BIN="$FLUTTER_ROOT/bin/dart"

if [ ! -x "$DART_BIN" ]; then
  DART_BIN="dart"
fi

# Ensure depot_tools is in PATH for git hooks
export PATH="$FLUTTER_ROOT/bin:/usr/local/google/home/boetger/src/depot_tools:$PATH"

CURRENT_BRANCH=$(git -C "$FLUTTER_ROOT" branch --show-current 2>/dev/null || echo "")

# Only enforce strict chain checks on android-embedder-migration-v10 branches
if [[ "$CURRENT_BRANCH" == android-embedder-migration-v10/* ]]; then
  echo "==> [Pre-Commit Guard] Verifying PR chain consistency for $CURRENT_BRANCH..."

  PR_CHAIN_SCRIPT="$FLUTTER_ROOT/.agents/skills/pr-chain-manager/scripts/pr_chain.dart"
  if [ -f "$PR_CHAIN_SCRIPT" ]; then
    "$DART_BIN" "$PR_CHAIN_SCRIPT" verify || {
      echo "ERROR: PR chain is misaligned or out of sync with its parent branch." >&2
      echo "Run 'dart $PR_CHAIN_SCRIPT rebase' to cascade rebases before committing." >&2
      exit 1
    }

    "$DART_BIN" analyze --fatal-infos "$PR_CHAIN_SCRIPT" || {
      echo "ERROR: Dart static analysis failed on pr_chain.dart." >&2
      exit 1
    }
  fi
  echo "==> [Pre-Commit Guard] Verification passed!"
fi

exit 0
