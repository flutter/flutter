#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import os
import sys


import common


def IsWindows():
  return sys.platform == 'cygwin' or sys.platform.startswith('win')


def main_run(args):
  filter_tests = []
  if args.filter_file:
    filter_tests = json.load(args.filter_file)

  perf_id = args.properties.get('perf-id')
  script_args = args.args
  test_suite = script_args[0]
  if IsWindows():
    script_args[0] += '.exe'

  with common.temporary_file() as tempfile_path:
    gtest_args = [
          '--target', args.build_config_fs,
          '--annotate', 'graphing',
          '--perf-id', perf_id,
          '--perf-dashboard-id', test_suite,
          '--results-url', args.properties.get('results-url'),
          '--slave-name', args.properties.get('slavename'),
          '--builder-name', args.properties.get('buildername'),
          '--build-number', str(args.properties.get('buildnumber')),
          '--log-processor-output-file', tempfile_path,
          '--test-type', test_suite,
    ]

    if 'android' == args.properties.get('target_platform'):
      gtest_args.extend([
          '--no-xvfb',
          '--run-python-script', os.path.join(
              args.paths['checkout'], 'build', 'android', 'test_runner.py'),
          'gtest', '--release',
          '--suite', test_suite,
          '--verbose',
      ])
    else:
      gtest_args.extend(['--xvfb'])
      gtest_args.extend(script_args)

    rc = common.run_runtest(args, gtest_args + filter_tests)

    with open(tempfile_path) as f:
      results = json.load(f)

  json.dump({
      'valid': bool(rc == 0),
      'failures': results['failed'],
  }, args.output)

  return rc


def main_compile_targets(args):
  if 'android' == args.properties.get('target_platform'):
    json.dump(['${name}_apk'], args.output)
  else:
    json.dump(['$name'], args.output)


if __name__ == '__main__':
  funcs = {
    'run': main_run,
    'compile_targets': main_compile_targets,
  }
  sys.exit(common.run_script(sys.argv[1:], funcs))
