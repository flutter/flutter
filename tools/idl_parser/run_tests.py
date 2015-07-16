#!/usr/bin/env python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import glob
import sys
import unittest

if __name__ == '__main__':
  suite = unittest.TestSuite()
  for testname in glob.glob('*_test.py'):
    print 'Adding Test: ' + testname
    module = __import__(testname[:-3])
    suite.addTests(unittest.defaultTestLoader.loadTestsFromModule(module))
  result = unittest.TextTestRunner(verbosity=2).run(suite)
  if result.wasSuccessful():
    sys.exit(0)
  else:
    sys.exit(1)
