# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `content_aware_hash.sh` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# -------------------------------------------------------------------------- #

$ErrorActionPreference = "Stop"

# When called from a submodule hook; these will override `git -C dir`
$env:GIT_DIR = $null
$env:GIT_INDEX_FILE = $null
$env:GIT_WORK_TREE = $null

$progName = Split-Path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (Get-Item $progName).parent.parent.FullName

# Cannot use '*' for files in this command
# DEPS: tracks third party dependencies related to building the engine
# engine: all the code in the engine folder
# bin/internal/release-candidate-branch.version: release marker
$trackedFiles = "DEPS", "engine", "bin/internal/release-candidate-branch.version"
$baseRef = "HEAD"
$currentBranch = (git -C "$flutterRoot" rev-parse --abbrev-ref HEAD).Trim()

# By default, the content hash is based on HEAD.
# For local development branches, we want to base the hash on the merge-base
# with the remote tracking branch, so that we don't rebuild the world every
# time we make a change to the engine.
#
# The following conditions are exceptions where we want to use HEAD.
# 1. The current branch is a release branch (main, master, stable, beta).
# 2. The current branch is a GitHub temporary merge branch.
# 3. The current branch is a release candidate branch.
# 4. The current checkout is a shallow clone.
# 5. There is no current branch. E.g. running on CI/CD.
$isShallow = Test-Path -Path (Join-Path "$flutterRoot" ".git/shallow")
if (($currentBranch -ne "main") -and
    ($currentBranch -ne "master") -and
    ($currentBranch -ne "stable") -and
    ($currentBranch -ne "beta") -and
    (-not (($currentBranch -eq "HEAD") -and (-not [string]::IsNullOrEmpty($env:LUCI_CONTEXT)))) -and
    (-not $currentBranch.StartsWith("gh-readonly-queue/master/pr-")) -and
    (-not ($currentBranch -like "flutter-*-candidate.*")) -and
    (-not $isShallow)) {

    # This is a development branch. Find the merge-base.
    # We will fallback to origin if upstream is not detected.
    $remote = "origin"
    $ErrorActionPreference = 'SilentlyContinue'
    git -C "$flutterRoot" remote get-url upstream *> $null
    if ($LASTEXITCODE -eq 0) {
        $remote = "upstream"
    }

    # Try to find the merge-base with master, then main.
    $mergeBase = (git -C "$flutterRoot" merge-base HEAD "$remote/master" 2>$null).Trim()
    if ([string]::IsNullOrEmpty($mergeBase)) {
        $mergeBase = (git -C "$flutterRoot" merge-base HEAD "$remote/main" 2>$null).Trim()
    }
    $ErrorActionPreference = "Stop"

    if ($mergeBase) {
        $baseRef = "$mergeBase"
    }
}

# Removing the "cmd" requirement enables powershell usage on other hosts
# 1. git ls-tree | Out-String - combines output of pipeline into a single string
#    rather than an array for each line.
#    "-NoNewline" not available on PS5.1 and also removes all newlines.
# 2. -replace "`r`n", "`n"  - removes line endings
#    NOTE: Out-String adds a new line; so Out-File -NoNewline strips that.
# 3. Out-File -NoNewline -Encoding ascii outputs 8bit ascii
# 4. git hash-object with stdin from a pipeline consumes UTF-16, so consume
#.   the contents of hash.txt
(git -C "$flutterRoot" ls-tree "$baseRef" -- $trackedFiles | Out-String) -replace "`r`n", "`n"  | Out-File -NoNewline -Encoding ascii hash.txt
git hash-object hash.txt
Remove-Item hash.txt
