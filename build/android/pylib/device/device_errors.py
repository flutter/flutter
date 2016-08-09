# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Exception classes raised by AdbWrapper and DeviceUtils.
"""

from pylib import cmd_helper
from pylib.utils import base_error


class CommandFailedError(base_error.BaseError):
  """Exception for command failures."""

  def __init__(self, message, device_serial=None):
    if device_serial is not None:
      message = '(device: %s) %s' % (device_serial, message)
    self.device_serial = device_serial
    super(CommandFailedError, self).__init__(message)


class AdbCommandFailedError(CommandFailedError):
  """Exception for adb command failures."""

  def __init__(self, args, output, status=None, device_serial=None,
               message=None):
    self.args = args
    self.output = output
    self.status = status
    if not message:
      adb_cmd = ' '.join(cmd_helper.SingleQuote(arg) for arg in self.args)
      message = ['adb %s: failed ' % adb_cmd]
      if status:
        message.append('with exit status %s ' % self.status)
      if output:
        message.append('and output:\n')
        message.extend('- %s\n' % line for line in output.splitlines())
      else:
        message.append('and no output.')
      message = ''.join(message)
    super(AdbCommandFailedError, self).__init__(message, device_serial)


class DeviceVersionError(CommandFailedError):
  """Exception for device version failures."""

  def __init__(self, message, device_serial=None):
    super(DeviceVersionError, self).__init__(message, device_serial)


class AdbShellCommandFailedError(AdbCommandFailedError):
  """Exception for shell command failures run via adb."""

  def __init__(self, command, output, status, device_serial=None):
    self.command = command
    message = ['shell command run via adb failed on the device:\n',
               '  command: %s\n' % command]
    message.append('  exit status: %s\n' % status)
    if output:
      message.append('  output:\n')
      if isinstance(output, basestring):
        output_lines = output.splitlines()
      else:
        output_lines = output
      message.extend('  - %s\n' % line for line in output_lines)
    else:
      message.append("  output: ''\n")
    message = ''.join(message)
    super(AdbShellCommandFailedError, self).__init__(
      ['shell', command], output, status, device_serial, message)


class CommandTimeoutError(base_error.BaseError):
  """Exception for command timeouts."""
  pass


class DeviceUnreachableError(base_error.BaseError):
  """Exception for device unreachable failures."""
  pass


class NoDevicesError(base_error.BaseError):
  """Exception for having no devices attached."""

  def __init__(self):
    super(NoDevicesError, self).__init__(
        'No devices attached.', is_infra_error=True)
