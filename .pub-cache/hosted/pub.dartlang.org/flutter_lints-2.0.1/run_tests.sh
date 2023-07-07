#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Dart sources are only allowed in the example directory.
filecount=`find . -name '*.dart' ! -path './example/*' | wc -l`
if [ $filecount -ne 0 ]
then
  echo 'Dart sources are not allowed in this package:'
  find . -name '*.dart'
  exit 1
fi
