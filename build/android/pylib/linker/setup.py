# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Setup for linker tests."""

import os
import sys

from pylib import constants
from pylib.linker import test_case
from pylib.linker import test_runner

sys.path.insert(0,
                os.path.join(constants.DIR_SOURCE_ROOT, 'build', 'util', 'lib',
                             'common'))
import unittest_util # pylint: disable=F0401

def Setup(args, _devices):
  """Creates a list of test cases and a runner factory.

  Args:
    args: an argparse.Namespace object.
  Returns:
    A tuple of (TestRunnerFactory, tests).
  """
  test_cases = [
      test_case.LinkerLibraryAddressTest,
      test_case.LinkerSharedRelroTest,
      test_case.LinkerRandomizationTest]

  low_memory_modes = [False, True]
  all_tests = [t(is_low_memory=m) for t in test_cases for m in low_memory_modes]

  if args.test_filter:
    all_test_names = [test.qualified_name for test in all_tests]
    filtered_test_names = unittest_util.FilterTestNames(all_test_names,
                                                        args.test_filter)
    all_tests = [t for t in all_tests \
                 if t.qualified_name in filtered_test_names]

  def TestRunnerFactory(device, _shard_index):
    return test_runner.LinkerTestRunner(device, args.tool)

  return (TestRunnerFactory, all_tests)
