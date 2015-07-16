# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


class BaseError(Exception):
  """Base error for all test runner errors."""

  def __init__(self, message, is_infra_error=False):
    super(BaseError, self).__init__(message)
    self._is_infra_error = is_infra_error

  @property
  def is_infra_error(self):
    """Property to indicate if error was caused by an infrastructure issue."""
    return self._is_infra_error