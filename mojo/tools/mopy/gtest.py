# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import sys
import logging

_logger = logging.getLogger()


def set_color():
  """Run gtests with color if we're on a TTY (and we're not being told
  explicitly what to do)."""
  if sys.stdout.isatty() and "GTEST_COLOR" not in os.environ:
    _logger.debug("Setting GTEST_COLOR=yes")
    os.environ["GTEST_COLOR"] = "yes"
