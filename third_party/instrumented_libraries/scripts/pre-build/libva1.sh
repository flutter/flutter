#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script does some preparations before build of instrumented libva1.

# autogen is only required on Precise.
NOCONFIGURE=1 ./autogen.sh

sed -i "s|-no-undefined -Wl,--no-undefined||g" dummy_drv_video/Makefile.in
