#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# git_files_changed.sh <hash|ref>
# Returns a list of files that change from the given hash or ref compared to HEAD.
#
# Example:
#  ./.github/scripts/git_files_changed.sh upstream/master
#  ./.github/scripts/git_files_changed.sh eccbe7d4f7ac6ebf35d342db58e37736ed6c60f9
if [ -z "$1" ]; then
  echo "Usage: $0 <hash|ref>" >&2
  exit 1
fi

BASE_REF="$1"

# Get the changed files using triple-dot syntax
# This automatically finds the common ancestor and ignores unrelated changes on the base branch
git diff --name-only "$BASE_REF"...HEAD
