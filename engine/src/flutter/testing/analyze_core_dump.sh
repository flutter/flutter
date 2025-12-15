#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Gather information from a core dump.
#
# This script can be invoked by the run_tests.py script after an
# engine test crashes.

BUILDROOT=$1
EXE=$2
CORE=$3
OUTPUT=$4

UNAME=$(uname)
if [ "$UNAME" == "Linux" ]; then
  if [ -x "$(command -v gdb)" ]; then
    GDB=gdb
  else
    NDK_VERSION="28.2.13676358"
    GDB=$BUILDROOT/flutter/third_party/android_tools/sdk/ndk/$NDK_VERSION/prebuilt/linux-x86_64/bin/gdb
  fi
  echo "GDB=$GDB"
  $GDB $EXE $CORE --batch -ex "thread apply all bt" > $OUTPUT
fi
