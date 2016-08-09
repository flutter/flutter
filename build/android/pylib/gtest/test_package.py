# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Base class representing GTest test packages."""
# pylint: disable=R0201


class TestPackage(object):

  """A helper base class for both APK and stand-alone executables.

  Args:
    suite_name: Name of the test suite (e.g. base_unittests).
  """
  def __init__(self, suite_name):
    self.suite_name = suite_name

  def ClearApplicationState(self, device):
    """Clears the application state.

    Args:
      device: Instance of DeviceUtils.
    """
    raise NotImplementedError('Method must be overridden.')

  def CreateCommandLineFileOnDevice(self, device, test_filter, test_arguments):
    """Creates a test runner script and pushes to the device.

    Args:
      device: Instance of DeviceUtils.
      test_filter: A test_filter flag.
      test_arguments: Additional arguments to pass to the test binary.
    """
    raise NotImplementedError('Method must be overridden.')

  def GetAllTests(self, device):
    """Returns a list of all tests available in the test suite.

    Args:
      device: Instance of DeviceUtils.
    """
    raise NotImplementedError('Method must be overridden.')

  def GetGTestReturnCode(self, _device):
    return None

  def SpawnTestProcess(self, device):
    """Spawn the test process.

    Args:
      device: Instance of DeviceUtils.

    Returns:
      An instance of pexpect spawn class.
    """
    raise NotImplementedError('Method must be overridden.')

  def Install(self, device):
    """Install the test package to the device.

    Args:
      device: Instance of DeviceUtils.
    """
    raise NotImplementedError('Method must be overridden.')

  def PullAppFiles(self, device, files, directory):
    """Pull application data from the device.

    Args:
      device: Instance of DeviceUtils.
      files: A list of paths relative to the application data directory to
        retrieve from the device.
      directory: The host directory to which files should be pulled.
    """
    raise NotImplementedError('Method must be overridden.')
