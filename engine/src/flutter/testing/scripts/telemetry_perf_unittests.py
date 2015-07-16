#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
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

  test_args = ['--retry-limit', '3']
  if 'android' == args.properties.get('target_platform'):
    test_args += ['--browser', 'android-chrome-shell', '--device', 'android']
  else:
    test_args += ['--browser', args.build_config_fs.lower()]

  with common.temporary_file() as tempfile_path:
    test_args += ['--write-full-results-to', tempfile_path]
    rc = common.run_runtest(args, [
        '--annotate', 'gtest',
        '--test-type', 'telemetry_perf_unittests',
        '--run-python-script',
        os.path.join(common.SRC_DIR, 'tools', 'perf', 'run_tests')
    ] + test_args + filter_tests)

    with open(tempfile_path) as f:
      results = json.load(f)

  parsed_results = common.parse_common_test_results(results, test_separator='.')
  failures = parsed_results['unexpected_failures']

  json.dump({
      'valid': bool(rc <= common.MAX_FAILURES_EXIT_STATUS and
                   ((rc == 0) or failures)),
      'failures': failures.keys(),
  }, args.output)

  return rc


def main_compile_targets(args):
  if 'android' == args.properties.get('target_platform'):
    json.dump(['chrome_shell_apk'], args.output)
  else:
    json.dump(['chrome'], args.output)


if __name__ == '__main__':
  funcs = {
    'run': main_run,
    'compile_targets': main_compile_targets,
  }
  sys.exit(common.run_script(sys.argv[1:], funcs))
