#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Simple testing utility to just run the mojom parser."""


import os.path
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                os.path.pardir, os.path.pardir))

from mojom.parse.parser import Parse, ParseError


def main(argv):
  if len(argv) < 2:
    print "usage: %s filename" % argv[0]
    return 0

  for filename in argv[1:]:
    with open(filename) as f:
      print "%s:" % filename
      try:
        print Parse(f.read(), filename)
      except ParseError, e:
        print e
        return 1

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
