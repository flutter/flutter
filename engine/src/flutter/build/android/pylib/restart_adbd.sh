#!/system/bin/sh

# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Android shell script to restart adbd on the device. This has to be run
# atomically as a shell script because stopping adbd prevents further commands
# from running (even if called in the same adb shell).

trap '' HUP
trap '' TERM
trap '' PIPE

function restart() {
  stop adbd
  start adbd
}

restart &
