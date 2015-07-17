#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script does some preparations before build of instrumented libgtk2.0-0.

# Use the system-installed gtk-update-icon-cache during building. Normally a
# just-built one is used, however in MSan builds it will crash due to
# uninstrumented dependencies.

sed -i "s|./gtk-update-icon-cache|/usr/bin/gtk-update-icon-cache|g" gtk/Makefile.am
autoreconf
