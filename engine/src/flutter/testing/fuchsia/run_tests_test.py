#!/usr/bin/env vpython3

# [VPYTHON:BEGIN]
# python_version: "3.8"
# wheel <
#   name: "infra/python/wheels/pyyaml/${platform}_${py_python}_${py_abi}"
#   version: "version:5.4.1.chromium.1"
# >
# [VPYTHON:END]

# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import os
import shutil
import sys
import tempfile
import unittest

from pathlib import Path
from unittest.mock import patch

# pylint is looking for a wrong //testing/run_tests.py.
# pylint: disable=no-member
import run_tests

run_tests.OUT_DIR = '/tmp/out/fuchsia_debug_x64'
os.makedirs(run_tests.OUT_DIR, exist_ok=True)


class RunTestsTest(unittest.TestCase):

  def test_resolve_both_package_and_packages(self):
    packages = run_tests.resolve_packages([{'package': 'abc'}, {'packages': ['abc', 'def']}])
    self.assertEqual(
        packages, {os.path.join(run_tests.OUT_DIR, 'abc'),
                   os.path.join(run_tests.OUT_DIR, 'def')}
    )

  def test_resolve_package_make_symbolic_link(self):
    Path(os.path.join(run_tests.OUT_DIR, 'abc-0.far')).touch()
    packages = run_tests.resolve_packages([
        {'package': 'abc-0.far'},
    ])
    self.assertEqual(packages, {os.path.join(run_tests.OUT_DIR, 'abc.far')})
    self.assertTrue(os.path.islink(os.path.join(run_tests.OUT_DIR, 'abc.far')))

  def test_build_test_cases_with_arguments(self):
    test_cases = run_tests.build_test_cases([
        {'test_command': 'test run abc'},
        {'test_command': 'test run def -- --args'},
    ])
    self.assertEqual(
        test_cases,
        [run_tests.TestCase(package='abc'),
         run_tests.TestCase(package='def', args='--args')]
    )

  def test_main_configures_orchestrate_and_symlinks(self):
    for variant, config_name, expected_pb, expected_engine in (
        ('ci/fuchsia_debug_x64_tester', 'orchestrate_x64.json', 'fuchsia-images/terminal/x64/',
         None),
        ('ci/fuchsia_debug_arm64_tester', 'orchestrate_x64_arm64.json',
         'fuchsia-images/terminal/qemu-arm64/', 'qemu'),
    ):
      with self.subTest(variant=variant), \
           tempfile.TemporaryDirectory() as temp_dir, \
           tempfile.TemporaryDirectory() as logs_dir:
        os.symlink('stale_sdk', os.path.join(temp_dir, 'fuchsia-sdk'))
        os.symlink('stale_images', os.path.join(temp_dir, 'fuchsia-images'))
        argv = ['run_tests.py']
        with patch.object(run_tests, 'OUT_DIR', temp_dir), \
             patch.object(run_tests, 'VARIANT', variant), \
             patch.object(sys, 'argv', argv), \
             patch.dict(os.environ, {'FLUTTER_LOGS_DIR': logs_dir}), \
             patch.object(run_tests, 'force_running_unattended'), \
             patch.object(run_tests, 'run_tests', return_value=0) as mock_run_tests:
          self.assertEqual(run_tests.main(), 0)
          self.assertEqual(os.readlink(os.path.join(temp_dir, 'fuchsia-sdk')), run_tests.SDK_ROOT)
          self.assertEqual(
              os.readlink(os.path.join(temp_dir, 'fuchsia-images')), run_tests.IMAGES_ROOT
          )
          self.assertIn('--orchestrate', argv)
          self.assertIn('--out-dir=' + temp_dir, argv)
          self.assertIn('--test-realm=/core/testing/system-tests', argv)
          self.assertIn('--logs-dir=' + logs_dir, argv)
          self.assertFalse(any(arg.startswith('--product') for arg in argv))
          mock_run_tests.assert_called_once()
          expected_config = os.path.join(os.path.dirname(run_tests.__file__), config_name)
          self.assertEqual(os.environ['FUCHSIA_ORCHESTRATE_CONFIG'], expected_config)
          with open(expected_config, 'r') as config_file:
            config = json.load(config_file)
          self.assertEqual(config['experiments'], ['orchestrate-error-on-test-failure'])
          self.assertEqual(config['emulator']['ffx_path'], 'fuchsia-sdk/tools/x64/ffx')
          self.assertEqual(config['emulator']['local_pb'], expected_pb)
          self.assertEqual(config['emulator']['build_ids'], ['.build-id', 'fuchsia-sdk/.build-id'])
          self.assertEqual(config['emulator'].get('engine'), expected_engine)


if __name__ == '__main__':
  try:
    unittest.main()
  finally:
    # Clean up the temporary files. Since it's in /tmp/, ignore the errors.
    shutil.rmtree(run_tests.OUT_DIR, ignore_errors=True)
