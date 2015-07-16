# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Logging utilities, for use with the standard logging module."""


import logging


def InitLogging(verbose_count):
  """Ensures that the logger (obtained via logging.getLogger(), as usual) is
  initialized, with the log level set as appropriate for |verbose_count|
  instances of --verbose on the command line."""

  assert(verbose_count >= 0)
  if verbose_count == 0:
    level = logging.WARNING
  elif verbose_count == 1:
    level = logging.INFO
  else:  # verbose_count >= 2
    level = logging.DEBUG

  logging.basicConfig(format="%(relativeCreated).3f:%(levelname)s:%(message)s")
  logger = logging.getLogger()
  logger.setLevel(level)

  logger.debug("Initialized logging: verbose_count=%d, level=%d" %
               (verbose_count, level))
