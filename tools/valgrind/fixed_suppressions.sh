#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

bugs=$(egrep -o 'bug_[0-9]+' tools/valgrind/memcheck/suppressions.txt |\
    sed -e 's/bug_//' | sort -n | uniq);
fixed_status='(Fixed|Verified|Duplicate|FixUnreleased|WontFix|Invalid|IceBox)'
fixed_status="${fixed_status}</span>"
for bug in $bugs; do
  echo "Checking bug #$bug";
  curl -s "http://code.google.com/p/chromium/issues/detail?id=$bug" |\
     egrep -q $fixed_status;
  if [ $? -eq 0 ]; then echo "Bug #$bug seems to be closed (http://crbug.com/$bug)"; fi
done
