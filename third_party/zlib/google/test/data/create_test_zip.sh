#!/bin/bash
#
# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Run this script in its directory to recreate test.zip
# and test_nocompress.zip.

rm test.zip
rm test_nocompress.zip
pushd test
zip -r ../test.zip .
zip -r -0 ../test_nocompress.zip .
popd
