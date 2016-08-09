#!/bin/bash
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Attach to or start a ContentShell process and debug it.
# See --help for details.
#
PROGDIR=$(dirname "$0")
export ADB_GDB_PROGNAME=$(basename "$0")
export ADB_GDB_ACTIVITY=.CronetSampleActivity
"$PROGDIR"/adb_gdb \
    --program-name=CronetSample \
    --package-name=org.chromium.cronet_sample_apk \
    "$@"
