#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys

from mopy.mojo_python_tests_runner import MojoPythonTestRunner


def main():
  test_dir_list = [
      # Tests of pylib bindings.
      os.path.join('mojo', 'public', 'tools', 'bindings', 'pylib'),
      # Tests of "mopy" python tools code.
      os.path.join('mojo', 'tools', 'mopy'),
      # Tests of python code in devtools.
      os.path.join('mojo', 'devtools', 'common', 'devtoolslib')
  ]

  for test_dir in test_dir_list:
    runner = MojoPythonTestRunner(test_dir)
    exit_code = runner.run()
    if exit_code:
      return exit_code


if __name__ == '__main__':
  sys.exit(main())
