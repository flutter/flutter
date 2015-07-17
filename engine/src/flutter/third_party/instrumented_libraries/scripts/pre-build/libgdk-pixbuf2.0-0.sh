#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script does some preparations before build of instrumented libgdk-pixbuf2.0-0.

# Use the system-installed gdk-pixbuf-query-loaders during building. Normally a
# just-built one is used, however in MSan builds it will crash due to
# uninstrumented dependencies.

sed -i "s|\$(top_builddir)/gdk-pixbuf/gdk-pixbuf-query-loaders|/usr/bin/gdk-pixbuf-query-loaders|g" gdk-pixbuf/Makefile.am
autoreconf
