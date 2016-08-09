#!/bin/bash
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

TPUT=$(which tput 2>/dev/null)
if test -x "$TPUT" && $TPUT setaf 1 >/dev/null ; then
    RED="$($TPUT setaf 1)"
    NORMAL="$($TPUT op)"
else
    RED=
    NORMAL=
fi

warn() {
    echo "${RED}WARNING:${NORMAL} $@"
}
