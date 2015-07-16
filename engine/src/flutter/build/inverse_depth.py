#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys


def DoMain(argv):
  depth = argv[0]
  return os.path.relpath(os.getcwd(), os.path.abspath(depth))


def main(argv):
  if len(argv) < 2:
    print "USAGE: inverse_depth.py depth"
    return 1
  print DoMain(argv[1:])
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
