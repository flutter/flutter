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
from typing import Any, Iterable, List, Mapping, NamedTuple, Set

# The import is coming from vpython wheel and pylint cannot find it.
import yaml  # pylint: disable=import-error

# The imports are coming from fuchsia/test_scripts and pylint cannot find them
# without setting a global init-hook which is less favorable.
# But this file will be executed as part of the CI, its correctness of importing
# is guaranteed.

sys.path.insert(
    0, os.path.join(os.path.dirname(__file__), '../../tools/fuchsia/test_scripts/test/')
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


# Visible for testing
class TestCase(NamedTuple):
  package: str
  args: str = ''


class _BundledTestRunner(TestRunner):

  # private, use bundled_test_runner_of function instead.
  def __init__(self, target_id: str, package_deps: Set[str], tests: List[TestCase], logs_dir: str):
    super().__init__(OUT_DIR, [], None, target_id, list(package_deps))
    self.tests = tests
    self.logs_dir = logs_dir

  def run_test(self) -> CompletedProcess:
    returncode = 0
    for test in self.tests:
      assert test.package.endswith('.cm')
      test_runner = ExecutableTestRunner(
          OUT_DIR, test.args.split(), test.package, self._target_id, None, self.logs_dir, [], None
      )
      # pylint: disable=protected-access
      test_runner._package_deps = self._package_deps
      result = test_runner.run_test().returncode
      logging.info('Result of test %s is %s', test, result)
      if result != 0:
        returncode = result
    return CompletedProcess(args='', returncode=returncode)


# Visible for testing
def resolve_packages(tests: Iterable[Mapping[str, Any]]) -> Set[str]:
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
  return resolved_packages


# Visible for testing
def build_test_cases(tests: Iterable[Mapping[str, Any]]) -> List[TestCase]:
  test_cases = []
  for test in [t['test_command'] for t in tests]:
    assert test.startswith('test run ')
    test = test[len('test run '):]
    if ' -- ' in test:
      package, args = test.split(' -- ', 1)
      test_cases.append(TestCase(package=package, args=args))
    else:
      test_cases.append(TestCase(package=test))
  return test_cases


def _bundled_test_runner_of(target_id: str) -> _BundledTestRunner:
  log_dir = os.environ.get('FLUTTER_LOGS_DIR', '/tmp/log')
  with open(os.path.join(os.path.dirname(__file__), 'test_suites.yaml'), 'r') as file:
    tests = yaml.safe_load(file)
  # TODO(zijiehe-google-com): Run all tests in release build,
  # https://github.com/flutter/flutter/issues/140179.
  def variant(test) -> bool:
    return 'variant' not in test or test['variant'] in VARIANT

  tests = [t for t in tests if variant(t)]
  return _BundledTestRunner(target_id, resolve_packages(tests), build_test_cases(tests), log_dir)


def _get_test_runner(runner_args: argparse.Namespace, *_) -> TestRunner:
  return _bundled_test_runner_of(runner_args.target_id)


if __name__ == '__main__':
  logging.basicConfig(level=logging.INFO)
  logging.info('Running tests in %s', OUT_DIR)
  sys.argv.append('--out-dir=' + OUT_DIR)
  if VARIANT.endswith('_arm64'):
    sys.argv.append('--product=terminal.qemu-arm64')
  # The 'flutter-test-type' is a place holder and has no specific meaning; the
  # _get_test_runner is overrided.
  sys.argv.append('flutter-test-type')
  run_test._get_test_runner = _get_test_runner  # pylint: disable=protected-access
  sys.exit(run_test.main())
