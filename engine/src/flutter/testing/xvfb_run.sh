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
# the test does. It does not reset: an X server regenerates itself (and
# runs xkbcomp again) each time its last client leaves, which under
# gtest-parallel is between every two test processes, and a client that
# connects while the server is regenerating can lose its connection -- GTK
# then says "cannot open display" for a display that is up. Alone on a
# machine the suite never hit it; with three of its instances sharing the
# machine, 14 of 20 runs did (a handful of the 1,710 test processes each),
# and none of 6 runs with -noreset. The server resets between sessions for
# nobody here.
#
# A sharded test (`shard_count`) gets Bazel's shard variables handed to
# googletest under the names it reads (the in-tree googletest knows only
# GTEST_*), and gtest touches the status file by which Bazel learns the
# shard was honoured. run_tests.py's gtest-parallel splits a suite the same
# way, one process per core.
#
# With FLUTTER_TEST_SESSION_BUS=1 (flutter_display_test's session_bus) the
# binary also gets a D-Bus session bus of its own, through dbus-run-session,
# unless the environment has one (DBUS_SESSION_BUS_ADDRESS). GTK's
# accessibility bridge (at-spi) asks the session bus for the accessibility
# bus, and a view's AtkPlug has no id without one: the Linux shell's suite
# then fails an Atk assertion in its first test, fatal under its G_DEBUG.
# run_tests.py's run inherits the bus of the session it runs in (a bot's
# systemd user session); a sandboxed test inherits nothing, so the wrapper
# starts one, as it starts the display. dbus-daemon and at-spi2-core (whose
# launcher the bus activates on demand) are host prerequisites, as GTK's
# own packages bring them. The wrapper asks the new bus for the
# accessibility bus once itself, before the binary runs: the launcher is
# activated by the first request, and when eight test processes make it at
# once (gtest-parallel's first wave) the launcher has been seen to
# disconnect under them, failing all eight with "Error retrieving
# accessibility bus address" (1 of 41 runs here); activated once, serially,
# it is there for everyone.
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

if [[ "${FLUTTER_TEST_SESSION_BUS:-}" == 1 && -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  if ! command -v dbus-run-session >/dev/null 2>&1; then
    echo "xvfb_run.sh: no DBUS_SESSION_BUS_ADDRESS in the environment and no" >&2
    echo "dbus-run-session on the PATH; the suite needs a D-Bus session bus" >&2
    echo "(install dbus, or run bazel test with --test_env=DBUS_SESSION_BUS_ADDRESS)." >&2
    exit 1
  fi
  # dbus-run-session exports the new bus's address to the command it runs:
  # this script again, which then goes on to the display.
  #
  # The session gets a home directory of its own under the test's temporary
  # directory. The sandbox mounts the real one read-only, and dconf --
  # GSettings' backend, which the accessibility bus launcher and the GTK
  # shell's GNOME settings both read through -- keeps a cache under it and
  # reports a critical when it cannot create the file; under the suite's
  # G_DEBUG=fatal-criticals that is an abort. An empty home also makes the
  # settings the schemas' defaults, which is what the suite's expectations
  # are (run_tests.py's run reads whatever the bot user has set).
  #
  # The daemon and the services it activates are not the test: they run
  # without its G_DEBUG (the launcher's own criticals would otherwise abort
  # it, and no accessibility bus would come up). The test binary gets it
  # back below.
  bus_scratch="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/xvfb_run.bus.XXXXXX")"
  mkdir -p "$bus_scratch/home"
  FLUTTER_TEST_SESSION_BUS=2 \
    FLUTTER_TEST_BUS_SCRATCH="$bus_scratch" \
    FLUTTER_TEST_SAVED_G_DEBUG="${G_DEBUG-}" \
    HOME="$bus_scratch/home" \
    exec env -u G_DEBUG dbus-run-session -- "$0" "$@"
fi
if [[ "${FLUTTER_TEST_SESSION_BUS:-}" == 2 ]]; then
  if [[ -n "$FLUTTER_TEST_SAVED_G_DEBUG" ]]; then
    export G_DEBUG="$FLUTTER_TEST_SAVED_G_DEBUG"
  fi
  unset FLUTTER_TEST_SESSION_BUS FLUTTER_TEST_SAVED_G_DEBUG
  echo "xvfb_run.sh: DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS HOME=$HOME" >&2
  # Activate the accessibility bus once, serially (see above). A failure
  # here is the binary's to report, in its own words.
  if command -v dbus-send >/dev/null 2>&1; then
    dbus-send --session --print-reply --dest=org.a11y.Bus /org/a11y/bus \
      org.a11y.Bus.GetAddress >/dev/null 2>&1 || :
  fi
fi

if [[ -n "${DISPLAY:-}" ]]; then
  exec "$@"
fi

# A Mac has no X server and needs none: run_tests.py runs the Impeller
# suites there as they are (the window server is the logged-in session's,
# on a bot as on a desk), with the Metal validation environment the rule
# sets (testing.bzl). The session bus above is GTK's, which no Mac suite
# asks for. The GPU test backends' directory goes on DYLD_LIBRARY_PATH
# (FLUTTER_TEST_LIBRARY_PATH, relative to the runfiles root the test runs
# from): the playground opens ANGLE's libGLESv2.dylib by its leaf name,
# which dyld finds there -- under run_tests.py in the working directory,
# GN's build directory. Exported here rather than by the rule because dyld
# strips DYLD_* from the environment of /bin/bash, a protected binary.
if [[ "$(uname -s)" == Darwin ]]; then
  if [[ -n "${FLUTTER_TEST_LIBRARY_PATH:-}" ]]; then
    export DYLD_LIBRARY_PATH="$PWD/$FLUTTER_TEST_LIBRARY_PATH${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
  fi
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
  if [[ -n "${FLUTTER_TEST_BUS_SCRATCH:-}" ]]; then
    rm -rf "$FLUTTER_TEST_BUS_SCRATCH"
  fi
}
trap clean_up EXIT

# Xvfb writes the display number to the descriptor once it listens.
Xvfb -displayfd 3 -screen 0 1280x800x24 -ac -dpi 96 -maxclients 512 \
  -extension MIT-SHM -nolisten tcp -noreset \
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
