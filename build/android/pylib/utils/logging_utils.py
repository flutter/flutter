# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import contextlib
import logging

@contextlib.contextmanager
def SuppressLogging(level=logging.ERROR):
  """Momentarilly suppress logging events from all loggers.

  TODO(jbudorick): This is not thread safe. Log events from other threads might
  also inadvertently dissapear.

  Example:

    with logging_utils.SuppressLogging():
      # all but CRITICAL logging messages are suppressed
      logging.info('just doing some thing') # not shown
      logging.critical('something really bad happened') # still shown

  Args:
    level: logging events with this or lower levels are suppressed.
  """
  logging.disable(level)
  yield
  logging.disable(logging.NOTSET)
