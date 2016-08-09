# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A temp file that automatically gets pushed and deleted from a device."""

# pylint: disable=W0622

import random
import time

from pylib import cmd_helper
from pylib.device import device_errors


class DeviceTempFile(object):
  def __init__(self, adb, suffix='', prefix='temp_file', dir='/data/local/tmp'):
    """Find an unused temporary file path in the devices external directory.

    When this object is closed, the file will be deleted on the device.

    Args:
      adb: An instance of AdbWrapper
      suffix: The suffix of the name of the temp file.
      prefix: The prefix of the name of the temp file.
      dir: The directory on the device where to place the temp file.
    """
    self._adb = adb
    # make sure that the temp dir is writable
    self._adb.Shell('test -d %s' % cmd_helper.SingleQuote(dir))
    while True:
      self.name = '{dir}/{prefix}-{time:d}-{nonce:d}{suffix}'.format(
        dir=dir, prefix=prefix, time=int(time.time()),
        nonce=random.randint(0, 1000000), suffix=suffix)
      self.name_quoted = cmd_helper.SingleQuote(self.name)
      try:
        self._adb.Shell('test -e %s' % self.name_quoted)
      except device_errors.AdbCommandFailedError:
        break # file does not exist

    # Immediately touch the file, so other temp files can't get the same name.
    self._adb.Shell('touch %s' % self.name_quoted)

  def close(self):
    """Deletes the temporary file from the device."""
    # ignore exception if the file is already gone.
    try:
      self._adb.Shell('rm -f %s' % self.name_quoted)
    except device_errors.AdbCommandFailedError:
      # file does not exist on Android version without 'rm -f' support (ICS)
      pass

  def __enter__(self):
    return self

  def __exit__(self, type, value, traceback):
    self.close()
