#!/bin/bash

# Copyright (c) 2009 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Usage: ./test_unmalicious_fonts.sh [ttf_or_otf_file_name]

BLACKLIST=./BLACKLIST.txt
CHECKER=./idempotent

if [ ! -r "$BLACKLIST" ] ; then
  echo "$BLACKLIST is not found."
  exit 1
fi

if [ ! -x "$CHECKER" ] ; then
  echo "$CHECKER is not found."
  exit 1
fi

if [ $# -eq 0 ] ; then
  # No font file is specified. Apply this script to all TT/OT files under the
  # BASE_DIR below.

  # On Ubuntu Linux (>= 8.04), You can install ~1800 TrueType/OpenType fonts
  # to /usr/share/fonts/truetype by:
  #   % sudo apt-get install ttf-.*[^0]$
  BASE_DIR=/usr/share/fonts/truetype/
  if [ ! -d $BASE_DIR ] ; then
    # Mac OS X
    BASE_DIR="/Library/Fonts/ /System/Library/Fonts/"
  fi
  # TODO(yusukes): Support Cygwin.

  # Recursively call this script.
  find $BASE_DIR -type f -name '*tf' -exec "$0" {} \;
  echo
  exit 0
fi

if [ $# -gt 1 ] ; then
  echo "Usage: $0 [ttf_or_otf_file_name]"
  exit 1
fi

# Check the font file using idempotent iff the font is not blacklisted.
base=`basename "$1"`
egrep -i -e "^$base" "$BLACKLIST" > /dev/null 2>&1 || "$CHECKER" "$1" > /dev/null 2>&1 || (echo ; echo "FAIL: $1 (Run $CHECKER $1 for more information.)")
echo -n "."
