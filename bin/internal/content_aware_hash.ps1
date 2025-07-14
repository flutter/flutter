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
# bin/internal/content_aware_hash.ps1: script for calculating the hash on windows
# bin/internal/content_aware_hash.sh: script for calculating the hash on mac/linux
# .github/workflows/content-aware-hash.yml: github action for CI/CD hashing
#
# Removing the "cmd" requirement enables powershell usage on other hosts
# 1. git ls-tree | Out-String - combines output of pipeline into a single string
#    rather than an array for each line.
#    "-NoNewline" not available on PS5.1 and also removes all newlines.
# 2. -replace "`r`n", "`n"  - removes line endings
#    NOTE: Out-String adds a new line; so Out-File -NoNewline strips that.
# 3. Out-File -NoNewline -Encoding ascii outputs 8bit ascii
# 4. git hash-object with stdin from a pipeline consumes UTF-16, so consume
#.   the contents of hash.txt
(git -C "$flutterRoot" ls-tree --format "%(objectname) %(path)" HEAD DEPS engine bin/internal/release-candidate-branch.version | Out-String) -replace "`r`n", "`n"  | Out-File -NoNewline -Encoding ascii hash.txt
git hash-object hash.txt
Remove-Item hash.txt
