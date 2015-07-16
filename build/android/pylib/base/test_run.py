# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


class TestRun(object):
  """An execution of a particular test on a particular device.

  This is expected to handle all logic that is specific to the combination of
  environment and test type.

  Examples include:
    - local gtests
    - local instrumentation tests
  """

  def __init__(self, env, test_instance):
    self._env = env
    self._test_instance = test_instance

  def TestPackage(self):
    raise NotImplementedError

  def SetUp(self):
    raise NotImplementedError

  def RunTests(self):
    raise NotImplementedError

  def TearDown(self):
    raise NotImplementedError

  def __enter__(self):
    self.SetUp()
    return self

  def __exit__(self, exc_type, exc_val, exc_tb):
    self.TearDown()

