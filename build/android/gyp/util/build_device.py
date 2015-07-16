# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

""" A simple device interface for build steps.

"""

import logging
import os
import re
import sys

from util import build_utils

BUILD_ANDROID_DIR = os.path.join(os.path.dirname(__file__), '..', '..')
sys.path.append(BUILD_ANDROID_DIR)

from pylib import android_commands
from pylib.device import device_errors
from pylib.device import device_utils

GetAttachedDevices = android_commands.GetAttachedDevices


class BuildDevice(object):
  def __init__(self, configuration):
    self.id = configuration['id']
    self.description = configuration['description']
    self.install_metadata = configuration['install_metadata']
    self.device = device_utils.DeviceUtils(self.id)

  def RunShellCommand(self, *args, **kwargs):
    return self.device.RunShellCommand(*args, **kwargs)

  def PushChangedFiles(self, *args, **kwargs):
    return self.device.PushChangedFiles(*args, **kwargs)

  def GetSerialNumber(self):
    return self.id

  def Install(self, *args, **kwargs):
    return self.device.Install(*args, **kwargs)

  def GetInstallMetadata(self, apk_package):
    """Gets the metadata on the device for the apk_package apk."""
    # Matches lines like:
    # -rw-r--r-- system   system    7376582 2013-04-19 16:34 \
    #   org.chromium.chrome.shell.apk
    # -rw-r--r-- system   system    7376582 2013-04-19 16:34 \
    #   org.chromium.chrome.shell-1.apk
    apk_matcher = lambda s: re.match('.*%s(-[0-9]*)?.apk$' % apk_package, s)
    matches = filter(apk_matcher, self.install_metadata)
    return matches[0] if matches else None


def GetConfigurationForDevice(device_id):
  device = device_utils.DeviceUtils(device_id)
  configuration = None
  has_root = False
  is_online = device.IsOnline()
  if is_online:
    cmd = 'ls -l /data/app; getprop ro.build.description'
    cmd_output = device.RunShellCommand(cmd)
    has_root = not 'Permission denied' in cmd_output[0]
    if not has_root:
      # Disable warning log messages from EnableRoot()
      logging.getLogger().disabled = True
      try:
        device.EnableRoot()
        has_root = True
      except device_errors.CommandFailedError:
        has_root = False
      finally:
        logging.getLogger().disabled = False
      cmd_output = device.RunShellCommand(cmd)

    configuration = {
        'id': device_id,
        'description': cmd_output[-1],
        'install_metadata': cmd_output[:-1],
      }
  return configuration, is_online, has_root


def WriteConfigurations(configurations, path):
  # Currently we only support installing to the first device.
  build_utils.WriteJson(configurations[:1], path, only_if_changed=True)


def ReadConfigurations(path):
  return build_utils.ReadJson(path)


def GetBuildDevice(configurations):
  assert len(configurations) == 1
  return BuildDevice(configurations[0])


def GetBuildDeviceFromPath(path):
  configurations = ReadConfigurations(path)
  if len(configurations) > 0:
    return GetBuildDevice(ReadConfigurations(path))
  return None

