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

if ($Env:CIRRUS_BASE_BRANCH -ne "master") {
  Write-Host "`$CIRRUS_BASE_BRANCH is `"$Env:CIRRUS_BASE_BRANCH`", no merge necessary."
  return
}

# On cirrus, github.com/flutter/flutter is configured as origin
$remote = "origin"
git fetch $remote

$remoteRevision=git rev-parse $remote/master
$headRevision=git rev-parse HEAD

Write-Host "Attempting to merge `"$remoteRevision`" into `"$headRevision`"..."

# To allow writing a local merge commit
git config user.email "flutter@example.com"
git config user.name "Flutter CI"

# -X renormalize will ignore EOL whitespace diffs in the merge
git merge "$remote/master" --no-edit --stat --no-verify -s recursive -Xignore-space-at-eol

if($?) {
  Write-Host "Merge Successful!"
}
else {
  git merge --abort
  git diff HEAD $remoteRevision
  Write-Host "Attempting to merge upstream master failed!"
  Write-Host "The merge has been aborted and tests will continue on the branch as"
  Write-Host "is. You will still need to resolve the conflict before merging this"
  Write-Host "PR to master:\n"
  Write-Host "> git fetch upstream"
  Write-Host "> git merge upstream/master"
  Write-Host "# resolve conflicts"
  Write-Host "> git add /path/to/resolved/file"
  Write-Host "> git commit"
  Write-Host "> git push\n"
}
