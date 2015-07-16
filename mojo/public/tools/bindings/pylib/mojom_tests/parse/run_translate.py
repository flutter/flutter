#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Simple testing utility to just run the mojom translate stage."""


import os.path
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                os.path.pardir, os.path.pardir))

from mojom.parse.parser import Parse
from mojom.parse.translate import Translate


def main(argv):
  if len(argv) < 2:
    print "usage: %s filename" % sys.argv[0]
    return 1

  for filename in argv[1:]:
    with open(filename) as f:
      print "%s:" % filename
      print Translate(Parse(f.read(), filename),
                      os.path.splitext(os.path.basename(filename))[0])

  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))
