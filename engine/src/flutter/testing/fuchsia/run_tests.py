#!/usr/bin/env vpython3

# [VPYTHON:BEGIN]
# python_version: "3.8"
# wheel <
#   name: "infra/python/wheels/pyyaml/${platform}_${py_python}_${py_abi}"
#   version: "version:5.4.1.chromium.1"
# >
# [VPYTHON:END]

# Copyright (c) 2013, the Flutter project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be found
# in the LICENSE file.

import argparse
import logging
import os
import sys

from subprocess import CompletedProcess
from typing import List, Set

# The import is coming from vpython wheel and pylint cannot find it.
import yaml  # pylint: disable=import-error

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

if len(sys.argv) == 2:
  VARIANT = sys.argv[1]
  sys.argv.pop()
elif len(sys.argv) == 1:
  VARIANT = 'fuchsia_debug_x64'
else:
  assert False, 'Expect only one parameter as the compile output directory.'
OUT_DIR = os.path.join(DIR_SRC_ROOT, 'out', VARIANT)


class BundledTestRunner(TestRunner):

  # private, use bundled_test_runner_of function instead.
  def __init__(
      self, target_id: str, package_deps: Set[str], tests: List[str],
      logs_dir: str
  ):
    super().__init__(OUT_DIR, [], None, target_id, list(package_deps))
    self.tests = tests
    self.logs_dir = logs_dir

  def run_test(self) -> CompletedProcess:
    returncode = 0
    for test in self.tests:
      # pylint: disable=protected-access
      test_runner = ExecutableTestRunner(
          OUT_DIR, [], test, self._target_id, None, self.logs_dir, [], None
      )
      test_runner._package_deps = self._package_deps
      result = test_runner.run_test().returncode
      logging.info('Result of test %s is %s', test, result)
      if result != 0:
        returncode = result
    return CompletedProcess(args='', returncode=returncode)


def bundled_test_runner_of(target_id: str) -> BundledTestRunner:
  log_dir = os.environ.get('FLUTTER_LOGS_DIR', '/tmp/log')
  with open(os.path.join(os.path.dirname(__file__), 'test_suites.yaml'),
            'r') as file:
    tests = yaml.safe_load(file)
  # TODO(zijiehe-google-com): Run tests with extra test arguments,
  # https://github.com/flutter/flutter/issues/140179.
  tests = list(
      filter(
          lambda test: test['test_command'].startswith('test run ') and test[
              'test_command'].endswith('.cm'), tests
      )
  )
  # TODO(zijiehe-google-com): Run tests with dart aot,
  # https://github.com/flutter/flutter/issues/140179.
  tests = list(
      filter(
          lambda test: 'run_with_dart_aot' not in test or test[
              'run_with_dart_aot'] != 'true', tests
      )
  )
  tests = list(
      filter(
          lambda test: 'variant' not in test or VARIANT == test['variant'],
          tests
      )
  )
  packages = set()
  for test in tests:
    if 'package' in test:
      packages.add(test['package'])
    else:
      assert 'packages' in test, \
             'Expect either one package or a list of packages'
      packages.update(test['packages'])
  resolved_packages = set()
  for package in packages:
    if package.endswith('-0.far'):
      # Make a symbolic link to match the name of the package itself without the
      # '-0.far' suffix.
      new_package = os.path.join(OUT_DIR, package.replace('-0.far', '.far'))
      try:
        # Remove the old one if it exists, usually happen on the devbox, so
        # ignore the FileNotFoundError.
        os.remove(new_package)
      except FileNotFoundError:
        pass
      os.symlink(package, new_package)
      resolved_packages.add(new_package)
    else:
      resolved_packages.add(os.path.join(OUT_DIR, package))
  return BundledTestRunner(
      target_id, resolved_packages,
      [test['test_command'][len('test run '):] for test in tests], log_dir
  )


def _get_test_runner(runner_args: argparse.Namespace, *_) -> TestRunner:
  return bundled_test_runner_of(runner_args.target_id)


if __name__ == '__main__':
  logging.basicConfig(level=logging.INFO)
  logging.info('Running tests in %s', OUT_DIR)
  sys.argv.append('--out-dir=' + OUT_DIR)
  # The 'flutter-test-type' is a place holder and has no specific meaning; the
  # _get_test_runner is overrided.
  sys.argv.append('flutter-test-type')
  run_test._get_test_runner = _get_test_runner  # pylint: disable=protected-access
  sys.exit(run_test.main())
