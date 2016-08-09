#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script does some preparations before build of instrumented udev.

# Required on Trusty due to autoconf version mismatch.
autoreconf --force

# Do not warn about undefined sanitizer symbols in object files.
sed -i "s/\(-Wl,--no-undefined\|-Wl,-z,defs\)//g" ./configure

# Do not fortify source (doesn't work with MSan).
sed -i "s/-D_FORTIFY_SOURCE=2/-U_FORTIFY_SOURCE/g" ./configure
