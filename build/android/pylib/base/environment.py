# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


class Environment(object):
  """An environment in which tests can be run.

  This is expected to handle all logic that is applicable to an entire specific
  environment but is independent of the test type.

  Examples include:
    - The local device environment, for running tests on devices attached to
      the local machine.
    - The local machine environment, for running tests directly on the local
      machine.
  """

  def __init__(self):
    pass

  def SetUp(self):
    raise NotImplementedError

  def TearDown(self):
    raise NotImplementedError

  def __enter__(self):
    self.SetUp()
    return self

  def __exit__(self, _exc_type, _exc_val, _exc_tb):
    self.TearDown()

