#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import errno
import optparse
import os.path
import shutil
import sys


def main(argv):
    parser = optparse.OptionParser()
    parser.add_option('--touch')

    options, args = parser.parse_args(argv[1:])
    if len(args) != 2:
        parser.error('Two arguments required.')

    source = os.path.abspath(args[0])
    target = os.path.abspath(args[1])
    try:
        os.symlink(source, target)
    except OSError, e:
        if e.errno == errno.EEXIST:
            os.remove(target)
            os.symlink(source, target)

    if options.touch:
        with open(os.path.abspath(options.touch), 'w') as f:
            pass


if __name__ == '__main__':
  sys.exit(main(sys.argv))
