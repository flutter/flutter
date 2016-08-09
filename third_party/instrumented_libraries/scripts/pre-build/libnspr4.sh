#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script does some preparations before build of instrumented libnspr4.

if [ -d nspr ]
then
  mv nspr/* .
elif [ -d mozilla/nsprpub ]
then
  mv mozilla/nsprpub/* .
else
  echo "libnspr4.sh: package has unexpected directory structure. Please update this script."
  return 1
fi
