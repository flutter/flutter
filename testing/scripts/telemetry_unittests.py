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

  with common.temporary_file() as tempfile_path:
    rc = common.run_runtest(args, [
        '--annotate', 'gtest',
        '--test-type', 'telemetry_unittests',
        '--run-python-script',
        os.path.join(common.SRC_DIR, 'tools', 'telemetry', 'run_tests'),
        '--browser', args.build_config_fs.lower(),
        '--retry-limit', '3',
        '--write-full-results-to', tempfile_path,
    ] + filter_tests)

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
  json.dump(['chrome'], args.output)


if __name__ == '__main__':
  funcs = {
    'run': main_run,
    'compile_targets': main_compile_targets,
  }
  sys.exit(common.run_script(sys.argv[1:], funcs))
