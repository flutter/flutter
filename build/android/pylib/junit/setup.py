# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from pylib.junit import test_runner

def Setup(args):
  """Creates a test runner factory for junit tests.

  Args:
    args: an argparse.Namespace object.
  Return:
    A (runner_factory, tests) tuple.
  """

  def TestRunnerFactory(_unused_device, _unused_shard_index):
    return test_runner.JavaTestRunner(args)

  return (TestRunnerFactory, ['JUnit tests'])

