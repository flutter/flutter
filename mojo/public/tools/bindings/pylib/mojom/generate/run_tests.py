#!/usr/bin/env python
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" Test runner for Mojom """

import subprocess
import sys

def TestMojom(testname, args):
  print '\nRunning unit tests for %s.' % testname
  try:
    args = [sys.executable, testname] + args
    subprocess.check_call(args, stdout=sys.stdout)
    print 'Succeeded'
    return 0
  except subprocess.CalledProcessError as err:
    print 'Failed with %s.' % str(err)
    return 1


def main(args):
  errors = 0
  errors += TestMojom('data_tests.py', ['--test'])
  errors += TestMojom('module_tests.py', ['--test'])
  errors += TestMojom('pack_tests.py', ['--test'])

  if errors:
    print '\nFailed tests.'
  return min(errors, 127)  # Make sure the return value doesn't "wrap".


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))
