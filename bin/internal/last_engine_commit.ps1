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

$ErrorActionPreference = "Stop" # Equivalent to 'set -e' in bash

$progName = Split-Path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (Get-Item $progName).parent.parent.FullName

$Path1 = Join-Path $flutterRoot "bin"
$Path2 = Join-Path $Path1 "internal"
$RELEASE_CANDIDATE_VERSION_PATH = Join-Path $Path2 "release-candidate-branch.version"

# 1. Determine the reference commit: the last commit that changed
#    'bin/internal/release-candidate-branch.version'.
#    This serves as the starting point for evaluating changes on the current branch.
$REFERENCE_COMMIT = ""
try {
    $REFERENCE_COMMIT = (git log -1 --pretty=format:%H -- "$RELEASE_CANDIDATE_VERSION_PATH" -ErrorAction Stop).Trim()
}
catch {
    # If git log fails (e.g., file not found or no history), $REFERENCE_COMMIT will remain empty.
}

# If we did not find this reference commit, fail.
if ([string]::IsNullOrEmpty($REFERENCE_COMMIT)) {
    Write-Error "Error: Could not determine a suitable engine commit." -ErrorAction Stop
    Write-Error "Current branch: $((git rev-parse --abbrev-ref HEAD).Trim())" -ErrorAction Stop
    Write-Error "No file $RELEASE_CANDIDATE_VERSION_PATH found, or it has no history." -ErrorAction Stop
    exit 1
}

# 2. Define the history range to search within: commits reachable from HEAD
#    but not from the REFERENCE_COMMIT. This focuses the search on commits
#    *unique to the current branch* since that file was last changed.
$HISTORY_RANGE = "$REFERENCE_COMMIT..HEAD"
$DEPS_PATH = Join-Path $flutterRoot "DEPS"
$ENGINE_PATH = Join-Path $flutterRoot "engine"

$ENGINE_COMMIT = (git log -1 --pretty=format:%H --ancestry-path $HISTORY_RANGE -- "$DEPS_PATH" "$ENGINE_PATH")

# 3. If no engine-related commit was found within the current branch's history,
#    fallback to the REFERENCE_COMMIT itself.
if ([string]::IsNullOrEmpty($ENGINE_COMMIT)) {
    $ENGINE_COMMIT = $REFERENCE_COMMIT
}

Write-Output $ENGINE_COMMIT
