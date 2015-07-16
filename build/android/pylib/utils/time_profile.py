# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import time


class TimeProfile(object):
  """Class for simple profiling of action, with logging of cost."""

  def __init__(self, description):
    self._starttime = None
    self._description = description
    self.Start()

  def Start(self):
    self._starttime = time.time()

  def Stop(self):
    """Stop profiling and dump a log."""
    if self._starttime:
      stoptime = time.time()
      logging.info('%fsec to perform %s',
                   stoptime - self._starttime, self._description)
      self._starttime = None
