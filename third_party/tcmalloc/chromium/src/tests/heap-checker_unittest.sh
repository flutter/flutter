#!/bin/sh

# Copyright (c) 2005, Google Inc.
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
# Runs the heap-checker unittest with various environment variables.
# This is necessary because we turn on features like the heap profiler
# and heap checker via environment variables.  This test makes sure
# they all play well together.

# We expect BINDIR and PPROF_PATH to be set in the environment.
# If not, we set them to some reasonable values
BINDIR="${BINDIR:-.}"
PPROF_PATH="${PPROF_PATH:-$BINDIR/src/pprof}"

if [ "x$1" = "x-h" -o "$1" = "x--help" ]; then
  echo "USAGE: $0 [unittest dir] [path to pprof]"
  echo "       By default, unittest_dir=$BINDIR, pprof_path=$PPROF_PATH"
  exit 1
fi

HEAP_CHECKER="${1:-$BINDIR}/heap-checker_unittest"
PPROF_PATH="${2:-$PPROF_PATH}"

TMPDIR=/tmp/heap_check_info
rm -rf $TMPDIR || exit 2
mkdir $TMPDIR || exit 3

# $1: value of heap-check env. var.
run_check() {
    export PPROF_PATH="$PPROF_PATH"
    [ -n "$1" ] && export HEAPCHECK="$1" || unset HEAPPROFILE

    echo -n "Testing $HEAP_CHECKER with HEAPCHECK=$1 ... "
    if $HEAP_CHECKER > $TMPDIR/output 2>&1; then
      echo "OK"
    else
      echo "FAILED"
      echo "Output from the failed run:"
      echo "----"
      cat $TMPDIR/output
      echo "----"      
      exit 4
    fi

    # If we set HEAPPROFILE, then we expect it to actually have emitted
    # a profile.  Check that it did.
    if [ -n "$HEAPPROFILE" ]; then
      [ -e "$HEAPPROFILE.0001.heap" ] || exit 5
    fi
}

run_check ""
run_check "local"
run_check "normal"
run_check "strict"

rm -rf $TMPDIR      # clean up

echo "PASS"
