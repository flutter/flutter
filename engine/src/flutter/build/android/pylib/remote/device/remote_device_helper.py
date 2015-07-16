# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Common functions and Exceptions for remote_device_*"""

from pylib.utils import base_error


class RemoteDeviceError(base_error.BaseError):
  """Exception to throw when problems occur with remote device service."""
  pass


def TestHttpResponse(response, error_msg):
  """Checks the Http response from remote device service.

  Args:
      response: response dict from the remote device service.
      error_msg: Error message to display if bad response is seen.
  """
  if response.status_code != 200:
    raise RemoteDeviceError(
        '%s (%d: %s)' % (error_msg, response.status_code, response.reason))
