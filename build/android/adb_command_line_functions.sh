#!/bin/bash
#
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Variables must be set before calling:
# CMD_LINE_FILE - Path on device to flags file.
# REQUIRES_SU - Set to 1 if path requires root.
function set_command_line() {
  SU_CMD=""
  if [[ "$REQUIRES_SU" = 1 ]]; then
    # Older androids accept "su -c", while newer use "su uid".
    SDK_LEVEL=$(adb shell getprop ro.build.version.sdk | tr -d '\r')
    # E.g. if no device connected.
    if [[ -z "$SDK_LEVEL" ]]; then
      exit 1
    fi
    SU_CMD="su -c"
    if (( $SDK_LEVEL >= 21 )); then
      SU_CMD="su 0"
    fi
  fi

  if [ $# -eq 0 ] ; then
    # If nothing specified, print the command line (stripping off "chrome ")
    adb shell "cat $CMD_LINE_FILE 2>/dev/null" | cut -d ' ' -s -f2-
  elif [ $# -eq 1 ] && [ "$1" = '' ] ; then
    # If given an empty string, delete the command line.
    set -x
    adb shell $SU_CMD rm $CMD_LINE_FILE >/dev/null
  else
    # Else set it.
    set -x
    adb shell "echo 'chrome $*' | $SU_CMD dd of=$CMD_LINE_FILE"
    # Prevent other apps from modifying flags (this can create security issues).
    adb shell $SU_CMD chmod 0664 $CMD_LINE_FILE
  fi
}

