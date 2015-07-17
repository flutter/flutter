#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import os
import sys


import common


def main_run(args):
  filter_tests = []
  if args.filter_file:
    filter_tests = json.load(args.filter_file)

  script_args = args.args
  test_suite = script_args[0]

  with common.temporary_file() as tempfile_path:
    cmd = [
        os.path.join(
            args.paths['checkout'], 'build', 'android', 'test_runner.py'),
        'gtest',
        '--release' if 'release' in args.build_config_fs.lower() else '--debug',
        '--suite', test_suite,
        '--verbose',
        '--flakiness-dashboard-server=http://test-results.appspot.com',
        '--json-results-file', tempfile_path,
    ]
    if filter_tests:
      cmd.extend(['--gtest-filter', ':'.join(filter_tests)])

    rc = common.run_command(cmd)

    with open(tempfile_path) as f:
      results = json.load(f)

  parsed_results = common.parse_gtest_test_results(results)

  json.dump({
      'valid': True,
      'failures': parsed_results['failures'],
  }, args.output)

  return rc


def main_compile_targets(args):
  json.dump(['${name}_apk'], args.output)


if __name__ == '__main__':
  funcs = {
    'run': main_run,
    'compile_targets': main_compile_targets,
  }
  sys.exit(common.run_script(sys.argv[1:], funcs))
