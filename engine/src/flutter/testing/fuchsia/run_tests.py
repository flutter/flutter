#!/usr/bin/env python3
# Copyright (c) 2013, the Flutter project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be found
# in the LICENSE file.

import argparse
import os
import sys

# The imports are coming from fuchsia/test_scripts and pylint cannot find them
# without setting a global init-hook which is less favorable.
# But this file will be executed as part of the CI, its correctness of importing
# is guaranteed.

sys.path.insert(
    0,
    os.path.join(
        os.path.dirname(__file__), '../../tools/fuchsia/test_scripts/test/'
    )
)

# pylint: disable=import-error, wrong-import-position
import run_test
from common import DIR_SRC_ROOT
from run_executable_test import ExecutableTestRunner
from test_runner import TestRunner

# TODO(https://github.com/flutter/flutter/issues/140179): Respect build
# configurations.
OUT_DIR = os.path.join(DIR_SRC_ROOT, 'out/fuchsia_debug_x64')


# TODO(https://github.com/flutter/flutter/issues/140179): Execute all the tests
# in
# https://github.com/flutter/engine/blob/main/testing/fuchsia/test_suites.yaml
# and avoid hardcoded paths.
def _get_test_runner(runner_args: argparse.Namespace, *_) -> TestRunner:
  return ExecutableTestRunner(
      OUT_DIR, [],
      'fuchsia-pkg://fuchsia.com/dart_runner_tests#meta/dart_runner_tests.cm',
      runner_args.target_id, None, '/tmp/log',
      [os.path.join(OUT_DIR, 'dart_runner_tests.far')], None
  )


if __name__ == '__main__':
  try:
    os.remove(os.path.join(OUT_DIR, 'dart_runner_tests.far'))
  except FileNotFoundError:
    pass
  os.symlink(
      'dart_runner_tests-0.far', os.path.join(OUT_DIR, 'dart_runner_tests.far')
  )
  sys.argv.append('--out-dir=' + OUT_DIR)
  # The 'flutter-test-type' is a place holder and has no specific meaning; the
  # _get_test_runner is overrided.
  sys.argv.append('flutter-test-type')
  run_test._get_test_runner = _get_test_runner  # pylint: disable=protected-access
  sys.exit(run_test.main())
