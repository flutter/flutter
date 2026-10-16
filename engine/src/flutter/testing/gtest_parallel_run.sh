#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs a googletest suite the way testing/run_tests.py runs the engine's:
# through gtest-parallel (flutter/third_party/gtest-parallel), which lists
# the suite's tests and runs each in a process of its own, every test twice
# (--repeat=2, run_tests.py's repeat_flags), on as many workers as the
# machine has cores. A test that leaks state into its process, or fails the
# second time round, fails here as it fails there; gtest's own summary lines
# give way to gtest-parallel's ("[N/M] Suite.Test (ms)" for each run, the
# failed tests' output in full).
#
# Under `bazel test` the suite's shards, if any, are gtest-parallel's
# (--shard_count/--shard_index from Bazel's variables; the GTEST_* names a
# wrapper before this one may have set are dropped, or each test's process
# would shard again and find its one test on another shard), its per-test
# logs go to the undeclared outputs, and its timing cache to the test's
# temporary directory.
#
# Usage: gtest_parallel_run.sh <python3> <gtest-parallel> [options...] <binary> -- [arguments...]
#   options:   gtest-parallel's own (run_tests.py's --timeout=90 for ui_unittests)
#   arguments: the binary's (flow_unittests' --golden-dir, after run_tests.py's --)

set -eu

python="$1"
runner="$2"
shift 2

options=(--repeat=2)
if [[ -n "${TEST_TOTAL_SHARDS:-}" ]]; then
  options+=("--shard_count=$TEST_TOTAL_SHARDS" "--shard_index=$TEST_SHARD_INDEX")
  if [[ -n "${TEST_SHARD_STATUS_FILE:-}" ]]; then
    touch "$TEST_SHARD_STATUS_FILE"
  fi
fi
unset GTEST_TOTAL_SHARDS GTEST_SHARD_INDEX GTEST_SHARD_STATUS_FILE
if [[ -n "${TEST_UNDECLARED_OUTPUTS_DIR:-}" ]]; then
  options+=("--output_dir=$TEST_UNDECLARED_OUTPUTS_DIR")
fi
cache="${TEST_TMPDIR:-${TMPDIR:-/tmp}}/gtest_parallel_run.cache"
mkdir -p "$cache"
export XDG_CACHE_HOME="$cache"

exec "$python" -B "$runner" "${options[@]}" "$@"
