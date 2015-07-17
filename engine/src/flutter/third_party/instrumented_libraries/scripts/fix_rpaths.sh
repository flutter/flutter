#!/bin/bash
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Changes all RPATHs in a given directory from XORIGIN to $ORIGIN
# See the comment about XORIGIN in instrumented_libraries.gyp

# Fixes rpath from XORIGIN to $ORIGIN in a single file $1.
function fix_rpath {
  if [ -w "$1" ]
  then
    # Only attempt to fix RPATH if the entry actually exists.
    # FIXME(earthdok): find out why zlib1g on Precise doesn't get RPATH set.
    if chrpath -l $1
    then
      echo "fix_rpaths.sh: fixing $1"
      chrpath -r $(chrpath $1 | cut -d " " -f 2 | sed s/XORIGIN/\$ORIGIN/g \
        | sed s/RPATH=//g) $1
    fi
  else
    # FIXME(earthdok): libcups2 DSOs are created non-writable, causing this
    # script to fail. As a temporary measure, ignore non-writable files.
    echo "fix_rpaths.sh: skipping non-writable file $1"
  fi
}

for i in $(find $1 | grep -P "\.so(.\d+)*$"); do
  fix_rpath $i
done
