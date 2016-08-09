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
    rc = common.run_command([
        sys.executable,
        os.path.join(common.SRC_DIR, 'chrome', 'test', 'nacl_test_injection',
                     'buildbot_nacl_integration.py'),
        '--mode', args.build_config_fs,
        '--json_build_results_output_file', tempfile_path,
    ] + filter_tests)

    with open(tempfile_path) as f:
      results = json.load(f)


  json.dump({
      'valid': True,
      'failures': [f['raw_name'] for f in results],
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
