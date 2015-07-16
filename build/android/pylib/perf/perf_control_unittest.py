# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
# pylint: disable=W0212

import os
import sys
import unittest

sys.path.append(os.path.join(os.path.dirname(__file__), os.pardir, os.pardir))

from pylib.device import device_utils
from pylib.perf import perf_control

class TestPerfControl(unittest.TestCase):
  def setUp(self):
    if not os.getenv('BUILDTYPE'):
      os.environ['BUILDTYPE'] = 'Debug'

    devices = device_utils.DeviceUtils.HealthyDevices()
    self.assertGreater(len(devices), 0, 'No device attached!')
    self._device = devices[0]

  def testHighPerfMode(self):
    perf = perf_control.PerfControl(self._device)
    try:
      perf.SetPerfProfilingMode()
      cpu_info = perf.GetCpuInfo()
      self.assertEquals(len(perf._cpu_files), len(cpu_info))
      for _, online, governor in cpu_info:
        self.assertTrue(online)
        self.assertEquals('performance', governor)
    finally:
      perf.SetDefaultPerfMode()

if __name__ == '__main__':
  unittest.main()
