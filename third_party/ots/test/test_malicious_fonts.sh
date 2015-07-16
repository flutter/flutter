#!/bin/bash

# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Usage: ./test_malicious_fonts.sh [ttf_or_otf_file_name]

BASE_DIR=~/malicious/
CHECKER=./validator-checker

if [ ! -x "$CHECKER" ] ; then
  echo "$CHECKER is not found."
  exit 1
fi

if [ $# -eq 0 ] ; then
  # No font file is specified. Apply this script to all TT/OT files under the
  # BASE_DIR.
  if [ ! -d $BASE_DIR ] ; then
    echo "$BASE_DIR does not exist."
    exit 1
  fi

  # Recursively call this script.
  find $BASE_DIR -type f -name '*tf' -exec "$0" {} \;
  echo
  exit 0
fi

if [ $# -gt 1 ] ; then
  echo "Usage: $0 [ttf_or_otf_file_name]"
  exit 1
fi

# Confirm that the malicious font file does not crash OTS nor OS font renderer. 
base=`basename "$1"`
"$CHECKER" "$1" > /dev/null 2>&1 || (echo ; echo "\nFAIL: $1 (Run $CHECKER $1 for more information.)")
echo -n "."
