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

import logging
import os
import subprocess
import sys

from typing import Any, Iterable, List, Mapping, NamedTuple, Set, Tuple

# The import is coming from vpython wheel and pylint cannot find it.
import yaml  # pylint: disable=import-error

# The imports are coming from fuchsia/test_scripts and pylint cannot find them
# without setting a global init-hook which is less favorable.
# But this file will be executed as part of the CI, its correctness of importing
# is guaranteed.

TEST_SCRIPTS_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '../../tools/fuchsia/test_scripts/test/')
)
sys.path.insert(0, TEST_SCRIPTS_DIR)

# pylint: disable=import-error, wrong-import-position
from common import catch_sigterm, DIR_SRC_ROOT, IMAGES_ROOT, SDK_ROOT
from compatible_utils import force_running_unattended
from test_env_setup import wait_for_env_setup

if len(sys.argv) == 2:
  VARIANT = sys.argv[1]
elif len(sys.argv) == 1:
  VARIANT = 'fuchsia_debug_x64'
else:
  assert False, 'Expect only one parameter as the compile output directory.'
OUT_DIR = os.path.join(DIR_SRC_ROOT, 'out', VARIANT)


class TestCase(NamedTuple):
  package: str
  args: Tuple[str, ...] = ()
  package_deps: Tuple[str, ...] = ()


def _force_symlink(src: str, dst: str) -> None:
  try:
    # Remove the old one if it exists, usually happen on the devbox, so
    # ignore the FileNotFoundError.
    os.remove(dst)
  except FileNotFoundError:
    pass
  os.symlink(src, dst)


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
      _force_symlink(package, new_package)
      resolved_packages.add(new_package)
    else:
      resolved_packages.add(os.path.join(OUT_DIR, package))
  return resolved_packages


# Visible for testing
def build_test_cases(tests: Iterable[Mapping[str, Any]]) -> List[TestCase]:
  test_cases = []
  for entry in tests:
    test = entry['test_command']
    assert test.startswith('test run ')
    test = test[len('test run '):]
    package_deps = tuple(sorted(resolve_packages([entry])))
    if ' -- ' in test:
      package, args = test.split(' -- ', 1)
      test_cases.append(
          TestCase(package=package, args=tuple(args.split()), package_deps=package_deps)
      )
    else:
      test_cases.append(TestCase(package=test, package_deps=package_deps))
  return test_cases


def main() -> int:
  catch_sigterm()
  logging.basicConfig(level=logging.INFO)
  logging.info('Running tests in %s', OUT_DIR)
  force_running_unattended()
  logs_dir = os.path.realpath(os.environ.get('FLUTTER_LOGS_DIR', '/tmp/log'))
  os.makedirs(logs_dir, exist_ok=True)
  with open(os.path.join(os.path.dirname(__file__), 'test_suites.yaml'), 'r') as file:
    tests = yaml.safe_load(file)

  # TODO(zijiehe-google-com): Run all tests in release build,
  # https://github.com/flutter/flutter/issues/140179.
  def variant(test) -> bool:
    return 'variant' not in test or test['variant'] in VARIANT

  test_cases = build_test_cases([t for t in tests if variant(t)])
  assert test_cases, 'No tests matched variant ' + VARIANT

  setup_cmd = [
      sys.executable,
      os.path.join(TEST_SCRIPTS_DIR, 'test_env_setup.py'),
      '--out-dir=' + OUT_DIR,
      '--logs-dir=' + logs_dir,
  ]
  if VARIANT.endswith('_arm64') or VARIANT.endswith('_arm64_tester'):
    setup_cmd.append('--product=terminal.qemu-arm64')
  elif VARIANT.endswith('_x64') or VARIANT.endswith('_x64_tester'):
    _force_symlink(SDK_ROOT, os.path.join(OUT_DIR, 'fuchsia-sdk'))
    _force_symlink(IMAGES_ROOT, os.path.join(OUT_DIR, 'fuchsia-images'))
    setup_cmd.append('--orchestrate')
  else:
    assert False, 'Unsupported variant ' + VARIANT
  for pkg in sorted({pkg for test_case in test_cases for pkg in test_case.package_deps}):
    setup_cmd.append('--packages=' + pkg)

  with subprocess.Popen(setup_cmd) as setup_proc:
    try:
      if not wait_for_env_setup(setup_proc, logs_dir):
        return setup_proc.returncode or 1
      returncode = 0
      for test_case in test_cases:
        assert test_case.package.endswith('.cm')
        result = subprocess.run([
            sys.executable,
            os.path.join(TEST_SCRIPTS_DIR, 'run_executable_test.py'),
            '--out-dir=' + OUT_DIR,
            '--test-name=' + test_case.package,
            '--test-realm=/core/testing/system-tests',
            '--logs-dir=' + logs_dir,
            *('--package-deps=' + pkg for pkg in test_case.package_deps),
            *test_case.args,
        ],
                                check=False).returncode
        logging.info('Result of test %s is %s', test_case, result)
        if result != 0:
          returncode = result
      return returncode
    finally:
      setup_proc.terminate()
      setup_proc.wait()


if __name__ == '__main__':
  sys.exit(main())
