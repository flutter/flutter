# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


class TestInstance(object):
  """A type of test.

  This is expected to handle all logic that is test-type specific but
  independent of the environment or device.

  Examples include:
    - gtests
    - instrumentation tests
  """

  def __init__(self):
    pass

  def TestType(self):
    raise NotImplementedError

  def SetUp(self):
    raise NotImplementedError

  def TearDown(self):
    raise NotImplementedError

  def __enter__(self):
    self.SetUp()
    return self

  def __exit__(self, _exc_type, _exc_val, _exc_tb):
    self.TearDown()

