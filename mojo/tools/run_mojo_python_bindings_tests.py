#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys

from mopy.mojo_python_tests_runner import MojoPythonTestRunner


class PythonBindingsTestRunner(MojoPythonTestRunner):
  def add_custom_commandline_options(self, parser):
    parser.add_argument('--build-dir', action='store',
                        help='path to the build output directory')

  def apply_customization(self, args):
    if args.build_dir:
      python_build_dir = os.path.join(args.build_dir, 'python')
      if python_build_dir not in sys.path:
        sys.path.append(python_build_dir)
      python_gen_dir = os.path.join(
          args.build_dir,
          'gen', 'mojo', 'public', 'interfaces', 'bindings', 'tests')
      if python_gen_dir not in sys.path:
        sys.path.append(python_gen_dir)


def main():
  runner = PythonBindingsTestRunner(os.path.join('mojo', 'python', 'tests'))
  sys.exit(runner.run())


if __name__ == '__main__':
  sys.exit(main())
