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
# Runs the heap-profiler unittest and makes sure the profile looks appropriate.
#
# We run under the assumption that if $HEAP_PROFILER is run with --help,
# it prints a usage line of the form
#   USAGE: <actual executable being run> [...]
#
# This is because libtool sometimes turns the 'executable' into a
# shell script which runs an actual binary somewhere else.

# We expect BINDIR and PPROF_PATH to be set in the environment.
# If not, we set them to some reasonable values
BINDIR="${BINDIR:-.}"
PPROF_PATH="${PPROF_PATH:-$BINDIR/src/pprof}"

if [ "x$1" = "x-h" -o "x$1" = "x--help" ]; then
  echo "USAGE: $0 [unittest dir] [path to pprof]"
  echo "       By default, unittest_dir=$BINDIR, pprof_path=$PPROF_PATH"
  exit 1
fi

HEAP_PROFILER="${1:-$BINDIR}/heap-profiler_unittest"
PPROF="${2:-$PPROF_PATH}"
TEST_TMPDIR=/tmp/heap_profile_info

# It's meaningful to the profiler, so make sure we know its state
unset HEAPPROFILE

rm -rf "$TEST_TMPDIR"
mkdir "$TEST_TMPDIR" || exit 2

num_failures=0

# Given one profile (to check the contents of that profile) or two
# profiles (to check the diff between the profiles), and a function
# name, verify that the function name takes up at least 90% of the
# allocated memory.  The function name is actually specified first.
VerifyMemFunction() {
  function="$1"
  shift

  # get program name.  Note we have to unset HEAPPROFILE so running
  # help doesn't overwrite existing profiles.
  exec=`unset HEAPPROFILE; $HEAP_PROFILER --help | awk '{print $2; exit;}'`

  if [ $# = 2 ]; then
    [ -f "$1" ] || { echo "Profile not found: $1"; exit 1; }
    [ -f "$2" ] || { echo "Profile not found: $2"; exit 1; }
    $PPROF --base="$1" $exec "$2" >"$TEST_TMPDIR/output.pprof" 2>&1
  else
    [ -f "$1" ] || { echo "Profile not found: $1"; exit 1; }
    $PPROF $exec "$1" >"$TEST_TMPDIR/output.pprof" 2>&1
  fi

  cat "$TEST_TMPDIR/output.pprof" \
      | tr -d % | awk '$6 ~ /^'$function'$/ && $2 > 90 {exit 1;}'
  if [ $? != 1 ]; then
    echo
    echo "--- Test failed for $function: didn't account for 90% of executable memory"
    echo "--- Program output:"
    cat "$TEST_TMPDIR/output"
    echo "--- pprof output:"
    cat "$TEST_TMPDIR/output.pprof"
    echo "---"
    num_failures=`expr $num_failures + 1`
  fi
}

VerifyOutputContains() {
  text="$1"

  if ! grep "$text" "$TEST_TMPDIR/output" >/dev/null 2>&1; then
    echo "--- Test failed: output does not contain '$text'"
    echo "--- Program output:"
    cat "$TEST_TMPDIR/output"
    echo "---"
    num_failures=`expr $num_failures + 1`
  fi
}

HEAPPROFILE="$TEST_TMPDIR/test"
HEAP_PROFILE_INUSE_INTERVAL="10240"   # need this to be 10Kb
HEAP_PROFILE_ALLOCATION_INTERVAL="$HEAP_PROFILE_INUSE_INTERVAL"
HEAP_PROFILE_DEALLOCATION_INTERVAL="$HEAP_PROFILE_INUSE_INTERVAL"
export HEAPPROFILE
export HEAP_PROFILE_INUSE_INTERVAL
export HEAP_PROFILE_ALLOCATION_INTERVAL
export HEAP_PROFILE_DEALLOCATION_INTERVAL

# We make the unittest run a child process, to test that the child
# process doesn't try to write a heap profile as well and step on the
# parent's toes.  If it does, we expect the parent-test to fail.
$HEAP_PROFILER 1 >$TEST_TMPDIR/output 2>&1     # run program, with 1 child proc

VerifyMemFunction Allocate2 "$HEAPPROFILE.1329.heap"
VerifyMemFunction Allocate "$HEAPPROFILE.1448.heap" "$HEAPPROFILE.1548.heap"

# Check the child process got to emit its own profile as well.
VerifyMemFunction Allocate2 "$HEAPPROFILE"_*.1329.heap
VerifyMemFunction Allocate "$HEAPPROFILE"_*.1448.heap "$HEAPPROFILE"_*.1548.heap

# Make sure we logged both about allocating and deallocating memory
VerifyOutputContains "62 MB allocated"
VerifyOutputContains "62 MB freed"

# Now try running without --heap_profile specified, to allow
# testing of the HeapProfileStart/Stop functionality.
$HEAP_PROFILER >"$TEST_TMPDIR/output2" 2>&1

rm -rf $TMPDIR      # clean up

if [ $num_failures = 0 ]; then
  echo "PASS"
else
  echo "Tests finished with $num_failures failures"
fi
exit $num_failures
