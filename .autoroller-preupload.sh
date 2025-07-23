#!/usr/bin/env bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is executed by the skia autoroller after the roll has happened but before
# the PR is uploaded. Previously this logic was hardcoded into the autoroller
# and was reserved for updating the LICENSE file. Now the autoroller delegates
# to this script.
# See also:
#   - https://skia-review.googlesource.com/c/buildbot/+/1025936
#   - https://issues.skia.org/issues/433551375

