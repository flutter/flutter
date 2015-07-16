# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import os
import tempfile

from pylib import cmd_helper
from pylib import constants
from pylib.base import base_test_result
from pylib.results import json_results

class JavaTestRunner(object):
  """Runs java tests on the host."""

  def __init__(self, args):
    self._package_filter = args.package_filter
    self._runner_filter = args.runner_filter
    self._sdk_version = args.sdk_version
    self._test_filter = args.test_filter
    self._test_suite = args.test_suite

  def SetUp(self):
    pass

  def RunTest(self, _test):
    """Runs junit tests from |self._test_suite|."""
    with tempfile.NamedTemporaryFile() as json_file:
      java_script = os.path.join(
          constants.GetOutDirectory(), 'bin', self._test_suite)
      command = [java_script,
                 '-test-jars', self._test_suite + '.jar',
                 '-json-results-file', json_file.name]
      if self._test_filter:
        command.extend(['-gtest-filter', self._test_filter])
      if self._package_filter:
        command.extend(['-package-filter', self._package_filter])
      if self._runner_filter:
        command.extend(['-runner-filter', self._runner_filter])
      if self._sdk_version:
        command.extend(['-sdk-version', self._sdk_version])
      return_code = cmd_helper.RunCmd(command)
      results_list = json_results.ParseResultsFromJson(
          json.loads(json_file.read()))
      return (results_list, return_code)

  def TearDown(self):
    pass

