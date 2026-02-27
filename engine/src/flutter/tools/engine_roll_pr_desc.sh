#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

if [[ $1 == '' ]]; then
  echo 'Usage: engine_roll_pr_desc.sh <from git hash>..<to git hash>'
  exit 1
fi
git log --oneline --no-merges --no-color $1 | sed 's/^/flutter\/engine@/g' |  sed -e 's/(\(#[0-9]*)\)/\(flutter\/engine\1/g'
