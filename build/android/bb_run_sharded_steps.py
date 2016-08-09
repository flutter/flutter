#!/usr/bin/env python
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""DEPRECATED!
TODO(bulach): remove me once all other repositories reference
'test_runner.py perf' directly.
"""

import optparse
import sys

from pylib import cmd_helper


def main(argv):
  parser = optparse.OptionParser()
  parser.add_option('-s', '--steps',
                    help='A JSON file containing all the steps to be '
                         'sharded.')
  parser.add_option('--flaky_steps',
                    help='A JSON file containing steps that are flaky and '
                         'will have its exit code ignored.')
  parser.add_option('-p', '--print_results',
                    help='Only prints the results for the previously '
                         'executed step, do not run it again.')
  options, _ = parser.parse_args(argv)
  if options.print_results:
    return cmd_helper.RunCmd(['build/android/test_runner.py', 'perf',
                              '--print-step', options.print_results])
  flaky_options = []
  if options.flaky_steps:
    flaky_options = ['--flaky-steps', options.flaky_steps]
  return cmd_helper.RunCmd(['build/android/test_runner.py', 'perf', '-v',
                            '--steps', options.steps] + flaky_options)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
