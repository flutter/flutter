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
# Author: Maxim Lifantsev
#
# Run the heap checker unittest in a mode where it is supposed to crash and
# return an error if it doesn't.

# We expect BINDIR to be set in the environment.
# If not, we set it to some reasonable value.
BINDIR="${BINDIR:-.}"

if [ "x$1" = "x-h" -o "x$1" = "x--help" ]; then
  echo "USAGE: $0 [unittest dir]"
  echo "       By default, unittest_dir=$BINDIR"
  exit 1
fi

EXE="${1:-$BINDIR}/heap-checker_unittest"
TMPDIR="/tmp/heap_check_death_info"

ALARM() {
  # You need perl to run pprof, so I assume it's installed
  perl -e '
    $timeout=$ARGV[0]; shift;
    $retval = 255;   # the default retval, for the case where we timed out
    eval {           # need to run in an eval-block to trigger during system()
      local $SIG{ALRM} = sub { die "alarm\n" };  # \n is required!
      alarm $timeout;
      $retval = system(@ARGV);
      # Make retval bash-style: exit status, or 128+n if terminated by signal n
      $retval = ($retval & 127) ? (128 + $retval) : ($retval >> 8);
      alarm 0;
    };
    exit $retval;  # return system()-retval, or 255 if system() never returned
' "$@"
}

# $1: timeout for alarm;
# $2: regexp of expected exit code(s);
# $3: regexp to match a line in the output;
# $4: regexp to not match a line in the output;
# $5+ args to pass to $EXE
Test() {
  # Note: make sure these varnames don't conflict with any vars outside Test()!
  timeout="$1"
  shift
  expected_ec="$1"
  shift
  expected_regexp="$1"
  shift
  unexpected_regexp="$1"
  shift

  echo -n "Testing $EXE with $@ ... "
  output="$TMPDIR/output"
  ALARM $timeout env "$@" $EXE > "$output" 2>&1
  actual_ec=$?
  ec_ok=`expr "$actual_ec" : "$expected_ec$" >/dev/null || echo false`
  matches_ok=`test -z "$expected_regexp" || \
              grep "$expected_regexp" "$output" >/dev/null 2>&1 || echo false`
  negmatches_ok=`test -z "$unexpected_regexp" || \
                 ! grep "$unexpected_regexp" "$output" >/dev/null 2>&1 || echo false`
  if $ec_ok && $matches_ok && $negmatches_ok; then
    echo "PASS"
    return 0  # 0: success
  fi
  # If we get here, we failed.  Now we just need to report why
  echo "FAIL"
  if [ $actual_ec -eq 255 ]; then  # 255 == SIGTERM due to $ALARM
    echo "Test was taking unexpectedly long time to run and so we aborted it."
    echo "Try the test case manually or raise the timeout from $timeout"
    echo "to distinguish test slowness from a real problem."
  else
    $ec_ok || \
      echo "Wrong exit code: expected: '$expected_ec'; actual: $actual_ec"
    $matches_ok || \
      echo "Output did not match '$expected_regexp'"
    $negmatches_ok || \
      echo "Output unexpectedly matched '$unexpected_regexp'"
  fi
  echo "Output from failed run:"
  echo "---"
  cat "$output"
  echo "---"
  return 1  # 1: failure
}

TMPDIR=/tmp/heap_check_death_info
rm -rf $TMPDIR || exit 1
mkdir $TMPDIR || exit 2

export HEAPCHECK=strict       # default mode

# These invocations should pass (0 == PASS):

# This tests that turning leak-checker off dynamically works fine
Test 120 0 "^PASS$" "" HEAPCHECK="" || exit 1

# This disables threads so we can cause leaks reliably and test finding them
Test 120 0 "^PASS$" "" HEAP_CHECKER_TEST_NO_THREADS=1 || exit 2

# Test that --test_cancel_global_check works
Test 20 0 "Canceling .* whole-program .* leak check$" "" \
  HEAP_CHECKER_TEST_TEST_LEAK=1 HEAP_CHECKER_TEST_TEST_CANCEL_GLOBAL_CHECK=1 || exit 3
Test 20 0 "Canceling .* whole-program .* leak check$" "" \
  HEAP_CHECKER_TEST_TEST_LOOP_LEAK=1 HEAP_CHECKER_TEST_TEST_CANCEL_GLOBAL_CHECK=1 || exit 4

# Test that very early log messages are present and controllable:
EARLY_MSG="Starting tracking the heap$"

Test 60 0 "$EARLY_MSG" "" \
  HEAPCHECK="" HEAP_CHECKER_TEST_TEST_LEAK=1 HEAP_CHECKER_TEST_NO_THREADS=1 \
  PERFTOOLS_VERBOSE=10 || exit 5
Test 60 0 "MemoryRegionMap Init$" "" \
  HEAPCHECK="" HEAP_CHECKER_TEST_TEST_LEAK=1 HEAP_CHECKER_TEST_NO_THREADS=1 \
  PERFTOOLS_VERBOSE=11 || exit 6
Test 60 0 "" "$EARLY_MSG" \
  HEAPCHECK="" HEAP_CHECKER_TEST_TEST_LEAK=1 HEAP_CHECKER_TEST_NO_THREADS=1 \
  PERFTOOLS_VERBOSE=-11 || exit 7

# These invocations should fail with very high probability,
# rather than return 0 or hang (1 == exit(1), 134 == abort(), 139 = SIGSEGV):

Test 60 1 "Exiting .* because of .* leaks$" "" \
  HEAP_CHECKER_TEST_TEST_LEAK=1 HEAP_CHECKER_TEST_NO_THREADS=1 || exit 8
Test 60 1 "Exiting .* because of .* leaks$" "" \
  HEAP_CHECKER_TEST_TEST_LOOP_LEAK=1 HEAP_CHECKER_TEST_NO_THREADS=1 || exit 9

# Test that we produce a reasonable textual leak report.
Test 60 1 "MakeALeak" "" \
          HEAP_CHECKER_TEST_TEST_LEAK=1 HEAP_CHECK_TEST_NO_THREADS=1 \
  || exit 10

# Test that very early log messages are present and controllable:
Test 60 1 "Starting tracking the heap$" "" \
  HEAP_CHECKER_TEST_TEST_LEAK=1 HEAP_CHECKER_TEST_NO_THREADS=1 PERFTOOLS_VERBOSE=10 \
  || exit 11
Test 60 1 "" "Starting tracking the heap" \
  HEAP_CHECKER_TEST_TEST_LEAK=1 HEAP_CHECKER_TEST_NO_THREADS=1 PERFTOOLS_VERBOSE=-10 \
  || exit 12

cd /    # so we're not in TMPDIR when we delete it
rm -rf $TMPDIR

echo "PASS"

exit 0
