#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs a test binary that opens a window (the Impeller playground: GLFW on
# X11) under a display. testing/run_tests.py starts an Xvfb for the Linux
# suites and exports DISPLAY; under `bazel test` each test (each shard)
# brings its own unless the environment already has one
# (--test_env=DISPLAY). Xvfb is a host prerequisite, as it is for
# run_tests.py.
#
# The server is started directly rather than through `xvfb-run -a`: that
# option picks a display number by scanning /tmp for lock files, and two
# tests starting at once -- sixteen shards do -- pick the same number and
# collide in the abstract socket namespace, which every sandbox on the
# machine shares (each has a /tmp of its own, so the lock files tell them
# nothing). `Xvfb -displayfd` picks the first number it can bind and reports
# it, which is atomic against that namespace. The server's arguments are
# testing/xvfb.py's (what run_tests.py starts): the screen, 96 dpi, no
# access control, 512 clients, and MIT-SHM disabled -- the X shared-memory
# path races with the client under load (an unchecked attach of a segment
# the client has already released), and six of sixteen shards died of it
# with the extension on. It listens on no TCP port, and lives as long as
# the test does.
#
# A sharded test (`shard_count`) gets Bazel's shard variables handed to
# googletest under the names it reads (the in-tree googletest knows only
# GTEST_*), and gtest touches the status file by which Bazel learns the
# shard was honoured. run_tests.py's gtest-parallel splits a suite the same
# way, one process per core.
#
# Usage: xvfb_run.sh <binary> <arguments>...

set -eu

# Should the shell stop on a failing command, say which: a shard that fails
# without a word from the binary is otherwise unreadable.
trap 'echo "xvfb_run.sh: failed at line $LINENO: $BASH_COMMAND" >&2' ERR

if [[ -n "${TEST_TOTAL_SHARDS:-}" ]]; then
  export GTEST_TOTAL_SHARDS="$TEST_TOTAL_SHARDS"
  export GTEST_SHARD_INDEX="$TEST_SHARD_INDEX"
  if [[ -n "${TEST_SHARD_STATUS_FILE:-}" ]]; then
    export GTEST_SHARD_STATUS_FILE="$TEST_SHARD_STATUS_FILE"
  fi
fi

if [[ -n "${DISPLAY:-}" ]]; then
  exec "$@"
fi

if ! command -v Xvfb >/dev/null 2>&1; then
  echo "xvfb_run.sh: no DISPLAY in the environment and no Xvfb on the PATH;" >&2
  echo "the suite opens a window and needs an X server (install xvfb, or run" >&2
  echo "bazel test with --test_env=DISPLAY)." >&2
  exit 1
fi

scratch="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/xvfb_run.XXXXXX")"
# The server's log stays with the test's outputs under Bazel.
xvfb_log="${TEST_UNDECLARED_OUTPUTS_DIR:-$scratch}/xvfb.log"
xvfb_pid=
clean_up() {
  if [[ -n "$xvfb_pid" ]]; then
    kill "$xvfb_pid" 2>/dev/null || :
    wait "$xvfb_pid" 2>/dev/null || :
  fi
  rm -rf "$scratch"
}
trap clean_up EXIT

# Xvfb writes the display number to the descriptor once it listens.
Xvfb -displayfd 3 -screen 0 1280x800x24 -ac -dpi 96 -maxclients 512 \
  -extension MIT-SHM -nolisten tcp \
  3>"$scratch/display" 2>"$xvfb_log" &
xvfb_pid=$!
for ((i = 0; i < 300; i++)); do
  if [[ -s "$scratch/display" ]]; then
    break
  fi
  if ! kill -0 "$xvfb_pid" 2>/dev/null; then
    echo "xvfb_run.sh: Xvfb exited before it had a display:" >&2
    cat "$xvfb_log" >&2
    xvfb_pid=
    exit 1
  fi
  sleep 0.1
done
if [[ ! -s "$scratch/display" ]]; then
  echo "xvfb_run.sh: Xvfb did not report a display within 30 s:" >&2
  cat "$xvfb_log" >&2
  exit 1
fi
read -r display_number < "$scratch/display"
export DISPLAY=":$display_number"
echo "xvfb_run.sh: DISPLAY=$DISPLAY (Xvfb pid $xvfb_pid)" >&2

set +e
trap - ERR
"$@"
status=$?
set -e
if [[ "$status" -ne 0 ]]; then
  echo "xvfb_run.sh: $1 exited with status $status" >&2
fi
exit "$status"
