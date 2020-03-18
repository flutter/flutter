#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -eo pipefail

if [[ "$CIRRUS_BASE_BRANCH" != 'master' ]]; then
  # This is not pre-submit for master, no merge necessary
  echo "\$CIRRUS_BASE_BRANCH is $GIT_BASE_BRANCH, no merge necessary."
  exit 0
fi

# On cirrus, github.com/flutter/flutter is configured as origin
REMOTE='origin'
git fetch "$REMOTE"

REMOTE_REVISION=$(git rev-parse "$REMOTE"/master)
HEAD_REVISION=$(git rev-parse HEAD)

echo "Attempting to merge $REMOTE_REVISION into $HEAD_REVISION..."

git config user.email 'flutter@example.com'
git config user.name 'Flutter CI'

git merge "$REMOTE/master" --no-edit --stat --no-verify || {
  git diff # log the merge conflict
  git merge --abort || true
  echo 'Attempting to merge upstream master failed!'
  echo 'The merge has been aborted and tests will continue on the branch as'
  echo 'is. You will still need to resolve the conflict before merging this'
  echo "PR to master:\n"
  echo '$ git fetch upstream'
  echo '$ git merge upstream/master'
  echo '# resolve conflicts'
  echo '$ git add /path/to/resolved/file'
  echo '$ git commit'
  echo "$ git push\n"
  exit 0
}

echo 'Merge successful!'
