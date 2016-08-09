#!/bin/sh
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to build binutils found in /build/binutils-XXXX when inside a chroot.
# Don't call this script yourself, instead use the build-all.sh script.

set -e

if [ -z "$1" ]; then
 echo "Directory of binutils not given."
 exit 1
fi

cd "$1"
./configure --enable-gold=default --enable-threads --enable-plugins \
  --prefix=/build/output
make -j8 all
make install
