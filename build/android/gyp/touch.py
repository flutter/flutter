#!/usr/bin/env python
#
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import sys

from util import build_utils

def main(argv):
  for f in argv[1:]:
    build_utils.Touch(f)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
