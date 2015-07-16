# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
from pylib import android_commands
from pylib.device import device_utils


class OmapThrottlingDetector(object):
  """Class to detect and track thermal throttling on an OMAP 4."""
  OMAP_TEMP_FILE = ('/sys/devices/platform/omap/omap_temp_sensor.0/'
                    'temperature')

  @staticmethod
  def IsSupported(device):
    return device.FileExists(OmapThrottlingDetector.OMAP_TEMP_FILE)

  def __init__(self, device):
    self._device = device

  @staticmethod
  def BecameThrottled(log_line):
    return 'omap_thermal_throttle' in log_line

  @staticmethod
  def BecameUnthrottled(log_line):
    return 'omap_thermal_unthrottle' in log_line

  @staticmethod
  def GetThrottlingTemperature(log_line):
    if 'throttle_delayed_work_fn' in log_line:
      return float([s for s in log_line.split() if s.isdigit()][0]) / 1000.0

  def GetCurrentTemperature(self):
    tempdata = self._device.ReadFile(OmapThrottlingDetector.OMAP_TEMP_FILE)
    return float(tempdata) / 1000.0


class ExynosThrottlingDetector(object):
  """Class to detect and track thermal throttling on an Exynos 5."""
  @staticmethod
  def IsSupported(device):
    return device.FileExists('/sys/bus/exynos5-core')

  def __init__(self, device):
    pass

  @staticmethod
  def BecameThrottled(log_line):
    return 'exynos_tmu: Throttling interrupt' in log_line

  @staticmethod
  def BecameUnthrottled(log_line):
    return 'exynos_thermal_unthrottle: not throttling' in log_line

  @staticmethod
  def GetThrottlingTemperature(_log_line):
    return None

  @staticmethod
  def GetCurrentTemperature():
    return None


class ThermalThrottle(object):
  """Class to detect and track thermal throttling.

  Usage:
    Wait for IsThrottled() to be False before running test
    After running test call HasBeenThrottled() to find out if the
    test run was affected by thermal throttling.
  """

  def __init__(self, device):
    # TODO(jbudorick) Remove once telemetry gets switched over.
    if isinstance(device, android_commands.AndroidCommands):
      device = device_utils.DeviceUtils(device)
    self._device = device
    self._throttled = False
    self._detector = None
    if OmapThrottlingDetector.IsSupported(device):
      self._detector = OmapThrottlingDetector(device)
    elif ExynosThrottlingDetector.IsSupported(device):
      self._detector = ExynosThrottlingDetector(device)

  def HasBeenThrottled(self):
    """True if there has been any throttling since the last call to
       HasBeenThrottled or IsThrottled.
    """
    return self._ReadLog()

  def IsThrottled(self):
    """True if currently throttled."""
    self._ReadLog()
    return self._throttled

  def _ReadLog(self):
    if not self._detector:
      return False
    has_been_throttled = False
    serial_number = str(self._device)
    log = self._device.RunShellCommand('dmesg -c')
    degree_symbol = unichr(0x00B0)
    for line in log:
      if self._detector.BecameThrottled(line):
        if not self._throttled:
          logging.warning('>>> Device %s thermally throttled', serial_number)
        self._throttled = True
        has_been_throttled = True
      elif self._detector.BecameUnthrottled(line):
        if self._throttled:
          logging.warning('>>> Device %s thermally unthrottled', serial_number)
        self._throttled = False
        has_been_throttled = True
      temperature = self._detector.GetThrottlingTemperature(line)
      if temperature is not None:
        logging.info(u'Device %s thermally throttled at %3.1f%sC',
                     serial_number, temperature, degree_symbol)

    if logging.getLogger().isEnabledFor(logging.DEBUG):
      # Print current temperature of CPU SoC.
      temperature = self._detector.GetCurrentTemperature()
      if temperature is not None:
        logging.debug(u'Current SoC temperature of %s = %3.1f%sC',
                      serial_number, temperature, degree_symbol)

      # Print temperature of battery, to give a system temperature
      dumpsys_log = self._device.RunShellCommand('dumpsys battery')
      for line in dumpsys_log:
        if 'temperature' in line:
          btemp = float([s for s in line.split() if s.isdigit()][0]) / 10.0
          logging.debug(u'Current battery temperature of %s = %3.1f%sC',
                        serial_number, btemp, degree_symbol)

    return has_been_throttled

