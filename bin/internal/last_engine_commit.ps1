# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Based on the current repository state, writes on stdout the last commit in the
# git tree that edited either `DEPS` or any file in the `engine/` sub-folder,
# which is used to ensure `bin/internal/engine.version` is set correctly.

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `last_engine_commit.sh` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# https://github.com/flutter/flutter/blob/main/docs/tool/Engine-artifacts.md.
#
# Want to test this script?
# $ cd dev/tools
# $ dart test test/last_engine_commit_test.dart
#
# -------------------------------------------------------------------------- #

$ErrorActionPreference = "Stop"

$progName = Split-Path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (Get-Item $progName).parent.parent.FullName
$gitToplevel = (git rev-parse --show-toplevel).Trim()
# 1. Determine when we diverged from master.
$MERGE_BASE_COMMIT = ""
try {
    $MERGE_BASE_COMMIT = (git merge-base HEAD master).Trim()
}
catch {
    # If git merge-base fails (e.g., master not found, no common history),
    # $MERGE_BASE_COMMIT will remain empty.
}

# If we did not find a merge-base, fail
if ([string]::IsNullOrEmpty($MERGE_BASE_COMMIT)) {
    Write-Error "Error: Could not determine a suitable engine commit." -ErrorAction Stop
    Write-Error "Current branch: $(git rev-parse --abbrev-ref HEAD).Trim()" -ErrorAction Stop
    Write-Error "Expected a different branch, from 'master', or a 'master' branch that exists and has history." -ErrorAction Stop
    exit 1
}

# 2. Define and search history range to search within (unique to changes on this branch).
$HISTORY_RANGE = "$MERGE_BASE_COMMIT..HEAD"
$DEPS_PATH = Join-Path $gitToplevel "DEPS"
$ENGINE_PATH = Join-Path $gitToplevel "engine"

$ENGINE_COMMIT = (git log -1 --pretty=format:%H --ancestry-path $HISTORY_RANGE -- "$DEPS_PATH" "$ENGINE_PATH")

# 3. If no engine-related commit was found within the current branch's history, fallback to the first commit on this branch.
if ([string]::IsNullOrEmpty($ENGINE_COMMIT)) {
    # Find the oldest commit on HEAD that is *not* reachable from MERGE_BASE_COMMIT.
    # This is the first commit *on this branch* after it diverged from 'master'.
    $ENGINE_COMMIT = (git log --pretty=format:%H --reverse --ancestry-path "$MERGE_BASE_COMMIT..HEAD" | Select-Object -First 1).Trim()

    # Final check: If even this fallback fails (which would be highly unusual if MERGE_BASE_COMMIT was found),
    # then something is truly wrong.
    if ([string]::IsNullOrEmpty($ENGINE_COMMIT)) {
        Write-Error "Error: Unexpected state. MERGE_BASE_COMMIT was found ($MERGE_BASE_COMMIT), but no commits found on current branch after it." -ErrorAction Stop
        Write-Error "Current branch: $((git rev-parse --abbrev-ref HEAD).Trim())" -ErrorAction Stop
        Write-Error "History range searched for fallback: $HISTORY_RANGE" -ErrorAction Stop
        Write-Error "All commits on current branch (for debug):" -ErrorAction Stop
        (git log --pretty=format:%H) | Write-Error -ErrorAction Stop
        exit 1
    }
}

Write-Output $ENGINE_COMMIT
