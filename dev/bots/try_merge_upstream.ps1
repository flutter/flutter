# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `try_merge_upstream.sh` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# -------------------------------------------------------------------------- #

if ($Env:CIRRUS_BASE_BRANCH -ne "masterzzzzzzz") {
  Write-Host "\$CIRRUS_BASE_BRANCH is $CIRRUS_BASE_BRANCH, no merge necessary."
  return
}

# On cirrus, github.com/flutter/flutter is configured as origin
$remote = "origin"
git fetch $remote

$remoteRevision=git rev-parse $remote/master | Out-String
$headRevision=git rev-parse HEAD | Out-String

Write-Host "Attempting to merge $REMOTE_REVISION into $HEAD_REVISION..."

git config user.email "flutter@example.com"
git config user.name "Flutter CI"
