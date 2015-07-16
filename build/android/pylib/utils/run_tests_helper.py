# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Helper functions common to native, java and host-driven test runners."""

import logging
import sys
import time


class CustomFormatter(logging.Formatter):
  """Custom log formatter."""

  #override
  def __init__(self, fmt='%(threadName)-4s  %(message)s'):
    # Can't use super() because in older Python versions logging.Formatter does
    # not inherit from object.
    logging.Formatter.__init__(self, fmt=fmt)
    self._creation_time = time.time()

  #override
  def format(self, record):
    # Can't use super() because in older Python versions logging.Formatter does
    # not inherit from object.
    msg = logging.Formatter.format(self, record)
    if 'MainThread' in msg[:19]:
      msg = msg.replace('MainThread', 'Main', 1)
    timediff = time.time() - self._creation_time
    return '%s %8.3fs %s' % (record.levelname[0], timediff, msg)


def SetLogLevel(verbose_count):
  """Sets log level as |verbose_count|."""
  log_level = logging.WARNING  # Default.
  if verbose_count == 1:
    log_level = logging.INFO
  elif verbose_count >= 2:
    log_level = logging.DEBUG
  logger = logging.getLogger()
  logger.setLevel(log_level)
  custom_handler = logging.StreamHandler(sys.stdout)
  custom_handler.setFormatter(CustomFormatter())
  logging.getLogger().addHandler(custom_handler)
