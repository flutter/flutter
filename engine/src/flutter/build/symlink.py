#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Make a symlink and optionally touch a file (to handle dependencies)."""


import errno
import optparse
import os.path
import sys


def Main(argv):
  parser = optparse.OptionParser()
  parser.add_option('-f', '--force', action='store_true')
  parser.add_option('--touch')

  options, args = parser.parse_args(argv[1:])
  if len(args) < 2:
    parser.error('at least two arguments required.')

  target = args[-1]
  sources = args[:-1]
  for s in sources:
    t = os.path.join(target, os.path.basename(s))
    try:
      os.symlink(s, t)
    except OSError, e:
      if e.errno == errno.EEXIST and options.force:
        os.remove(t)
        os.symlink(s, t)
      else:
        raise


  if options.touch:
    with open(options.touch, 'w') as f:
      pass


if __name__ == '__main__':
  sys.exit(Main(sys.argv))
