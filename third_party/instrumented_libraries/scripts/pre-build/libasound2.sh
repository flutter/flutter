#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script does some preparations before build of instrumented libasound2.

# Instructions from the INSTALL file.
libtoolize --force --copy --automake
aclocal
autoheader
autoconf
automake --foreign --copy --add-missing

# Do not warn about undefined sanitizer symbols in object files.
sed -i "s/\(-Wl,--no-undefined\|-Wl,-z,defs\)//g" ./configure
