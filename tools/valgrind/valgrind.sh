#!/bin/bash

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is a small script for manually launching valgrind, along with passing
# it the suppression file, and some helpful arguments (automatically attaching
# the debugger on failures, etc).  Run it from your repo root, something like:
#  $ sh ./tools/valgrind/valgrind.sh ./out/Debug/chrome
#
# This is mostly intended for running the chrome browser interactively.
# To run unit tests, you probably want to run chrome_tests.sh instead.
# That's the script used by the valgrind buildbot.

export THISDIR=`dirname $0`

setup_memcheck() {
  RUN_COMMAND="valgrind"

  # Prompt to attach gdb when there was an error detected.
  DEFAULT_TOOL_FLAGS=("--db-command=gdb -nw %f %p" "--db-attach=yes" \
                      # Keep the registers in gdb in sync with the code.
                      "--vex-iropt-register-updates=allregs-at-mem-access" \
                      # Overwrite newly allocated or freed objects
                      # with 0x41 to catch inproper use.
                      "--malloc-fill=41" "--free-fill=41" \
                      # Increase the size of stacks being tracked.
                      "--num-callers=30")
}

setup_unknown() {
  echo "Unknown tool \"$TOOL_NAME\" specified, the result is not guaranteed"
  DEFAULT_TOOL_FLAGS=()
}

set -e

if [ $# -eq 0 ]; then
  echo "usage: <command to run> <arguments ...>"
  exit 1
fi

TOOL_NAME="memcheck"
declare -a DEFAULT_TOOL_FLAGS[0]

# Select a tool different from memcheck with --tool=TOOL as a first argument
TMP_STR=`echo $1 | sed 's/^\-\-tool=//'`
if [ "$TMP_STR" != "$1" ]; then
  TOOL_NAME="$TMP_STR"
  shift
fi

if echo "$@" | grep "\-\-tool" ; then
  echo "--tool=TOOL must be the first argument" >&2
  exit 1
fi

case $TOOL_NAME in
  memcheck*)  setup_memcheck "$1";;
  *)          setup_unknown;;
esac


SUPPRESSIONS="$THISDIR/$TOOL_NAME/suppressions.txt"

CHROME_VALGRIND=`sh $THISDIR/locate_valgrind.sh`
if [ "$CHROME_VALGRIND" = "" ]
then
  # locate_valgrind.sh failed
  exit 1
fi
echo "Using valgrind binaries from ${CHROME_VALGRIND}"

set -x
PATH="${CHROME_VALGRIND}/bin:$PATH"
# We need to set these variables to override default lib paths hard-coded into
# Valgrind binary.
export VALGRIND_LIB="$CHROME_VALGRIND/lib/valgrind"
export VALGRIND_LIB_INNER="$CHROME_VALGRIND/lib/valgrind"

# G_SLICE=always-malloc: make glib use system malloc
# NSS_DISABLE_UNLOAD=1: make nss skip dlclosing dynamically loaded modules,
# which would result in "obj:*" in backtraces.
# NSS_DISABLE_ARENA_FREE_LIST=1: make nss use system malloc
# G_DEBUG=fatal_warnings: make  GTK abort on any critical or warning assertions.
# If it crashes on you in the Options menu, you hit bug 19751,
# comment out the G_DEBUG=fatal_warnings line.
#
# GTEST_DEATH_TEST_USE_FORK=1: make gtest death tests valgrind-friendly
#
# When everyone has the latest valgrind, we might want to add
#  --show-possibly-lost=no
# to ignore possible but not definite leaks.

G_SLICE=always-malloc \
NSS_DISABLE_UNLOAD=1 \
NSS_DISABLE_ARENA_FREE_LIST=1 \
G_DEBUG=fatal_warnings \
GTEST_DEATH_TEST_USE_FORK=1 \
$RUN_COMMAND \
  --trace-children=yes \
  --leak-check=yes \
  --suppressions="$SUPPRESSIONS" \
  "${DEFAULT_TOOL_FLAGS[@]}" \
  "$@"
