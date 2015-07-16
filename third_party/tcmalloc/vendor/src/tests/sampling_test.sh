#!/bin/sh

# Copyright (c) 2008, Google Inc.
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
#
# ---
# Author: Craig Silverstein
#
# This is a test that tcmalloc creates, and pprof reads, sampling data
# correctly: both for the heap profile (ReadStackTraces) and for
# growth in the heap sized (ReadGrowthStackTraces).

BINDIR="${BINDIR:-.}"
PPROF_PATH="${PPROF_PATH:-$BINDIR/src/pprof}"

if [ "x$1" = "x-h" -o "x$1" = "x--help" ]; then
  echo "USAGE: $0 [unittest dir] [path to pprof]"
  echo "       By default, unittest_dir=$BINDIR, pprof_path=$PPROF_PATH"
  exit 1
fi

SAMPLING_TEST="${1:-$BINDIR/sampling_test}"
PPROF="${2:-$PPROF_PATH}"
OUTDIR="/tmp/sampling_test_dir"

# libtool is annoying, and puts the actual executable in a different
# directory, replacing the seeming-executable with a shell script.
# We use the error output of sampling_test to indicate its real location
SAMPLING_TEST_BINARY=`"$SAMPLING_TEST" 2>&1 | awk '/USAGE/ {print $2; exit;}'`

# A kludge for cygwin.  Unfortunately, 'test -f' says that 'foo' exists
# even when it doesn't, and only foo.exe exists.  Other unix utilities
# (like nm) need you to say 'foo.exe'.  We use one such utility, cat, to
# see what the *real* binary name is.
if ! cat "$SAMPLING_TEST_BINARY" >/dev/null 2>&1; then
  SAMPLING_TEST_BINARY="$SAMPLING_TEST_BINARY".exe
fi

die() {    # runs the command given as arguments, and then dies.
    echo "FAILED.  Output from $@"
    echo "----"
    "$@"
    echo "----"
    exit 1
}

rm -rf "$OUTDIR" || die "Unable to delete $OUTDIR"
mkdir "$OUTDIR" || die "Unable to create $OUTDIR"

# This puts the output into out.heap and out.growth.  It allocates
# 8*10^7 bytes of memory, which is 76M.  Because we sample, the
# estimate may be a bit high or a bit low: we accept anything from
# 50M to 99M.
"$SAMPLING_TEST" "$OUTDIR/out"

echo "Testing heap output..."
"$PPROF" --text "$SAMPLING_TEST_BINARY" "$OUTDIR/out.heap" \
   | grep '[5-9][0-9]\.[0-9][ 0-9.%]*_*AllocateAllocate' >/dev/null \
   || die "$PPROF" --text "$SAMPLING_TEST_BINARY" "$OUTDIR/out.heap"
echo "OK"

echo "Testing growth output..."
"$PPROF" --text "$SAMPLING_TEST_BINARY" "$OUTDIR/out.growth" \
   | grep '[5-9][0-9]\.[0-9][ 0-9.%]*_*AllocateAllocate' >/dev/null \
   || die "$PPROF" --text "$SAMPLING_TEST_BINARY" "$OUTDIR/out.growth"
echo "OK"

echo "PASS"
