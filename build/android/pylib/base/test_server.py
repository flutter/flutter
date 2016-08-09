# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

class TestServer(object):
  """Base class for any server that needs to be set up for the tests."""

  def __init__(self, *args, **kwargs):
    pass

  def SetUp(self):
    raise NotImplementedError

  def Reset(self):
    raise NotImplementedError

  def TearDown(self):
    raise NotImplementedError

