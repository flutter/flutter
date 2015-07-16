#!/bin/sh

# Copyright (c) 2007, Google Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# ---
# Author: Craig Silverstein
#
# maybe_threads.cc was written to allow LD_PRELOAD=libtcmalloc.so to
# work even on binaries that were not linked with pthreads.  This
# unittest tests that, by running low_level_alloc_unittest with an
# LD_PRELOAD.  (low_level_alloc_unittest was chosen because it doesn't
# link in tcmalloc.)
#
# We assume all the .so files are in the same directory as both
# addressmap_unittest and profiler1_unittest.  The reason we need
# profiler1_unittest is because it's instrumented to show the directory
# it's "really" in when run without any args.  In practice this will either
# be BINDIR, or, when using libtool, BINDIR/.lib.

# We expect BINDIR to be set in the environment.
# If not, we set them to some reasonable values.
BINDIR="${BINDIR:-.}"

if [ "x$1" = "x-h" -o "x$1" = "x--help" ]; then
  echo "USAGE: $0 [unittest dir]"
  echo "       By default, unittest_dir=$BINDIR"
  exit 1
fi

UNITTEST_DIR=${1:-$BINDIR}

# Figure out the "real" unittest directory.  Also holds the .so files.
UNITTEST_DIR=`$UNITTEST_DIR/low_level_alloc_unittest --help 2>&1 \
              | awk '{print $2; exit;}' \
              | xargs dirname`

# Figure out where libtcmalloc lives.   It should be in UNITTEST_DIR,
# but with libtool it might be in a subdir.
if [ -r "$UNITTEST_DIR/libtcmalloc_minimal.so" ]; then
  LIB_PATH="$UNITTEST_DIR/libtcmalloc_minimal.so"
elif [ -r "$UNITTEST_DIR/.libs/libtcmalloc_minimal.so" ]; then
  LIB_PATH="$UNITTEST_DIR/.libs/libtcmalloc_minimal.so"
elif [ -r "$UNITTEST_DIR/libtcmalloc_minimal.dylib" ]; then   # for os x
  LIB_PATH="$UNITTEST_DIR/libtcmalloc_minimal.dylib"
elif [ -r "$UNITTEST_DIR/.libs/libtcmalloc_minimal.dylib" ]; then
  LIB_PATH="$UNITTEST_DIR/.libs/libtcmalloc_minimal.dylib"
else
  echo "Cannot run $0: cannot find libtcmalloc_minimal.so"
  exit 2
fi

LD_PRELOAD="$LIB_PATH" $UNITTEST_DIR/low_level_alloc_unittest
