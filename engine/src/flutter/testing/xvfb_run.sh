#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs a test binary that opens a window (the Impeller playground: GLFW on
# X11) under a display. testing/run_tests.py starts an Xvfb for the Linux
# suites and exports DISPLAY; under `bazel test` each suite brings its own,
# through xvfb-run, unless the environment already has one
# (--test_env=DISPLAY). Xvfb is a host prerequisite, as it is for
# run_tests.py.
#
# Usage: xvfb_run.sh <binary> <arguments>...

set -eu

if [[ -n "${DISPLAY:-}" ]]; then
  exec "$@"
fi

if command -v xvfb-run >/dev/null 2>&1; then
  # -a picks a free display number; the server stays private to this test.
  exec xvfb-run -a -s "-screen 0 1280x1024x24" "$@"
fi

echo "xvfb_run.sh: no DISPLAY in the environment and no xvfb-run on the PATH;" >&2
echo "the suite opens a window and needs an X server (install xvfb, or run" >&2
echo "bazel test with --test_env=DISPLAY)." >&2
exit 1
