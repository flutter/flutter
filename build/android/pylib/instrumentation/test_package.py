# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Class representing instrumentation test apk and jar."""

import os

from pylib.instrumentation import test_jar
from pylib.utils import apk_helper


class TestPackage(test_jar.TestJar):
  def __init__(self, apk_path, jar_path, test_support_apk_path):
    test_jar.TestJar.__init__(self, jar_path)

    if not os.path.exists(apk_path):
      raise Exception('%s not found, please build it' % apk_path)
    self._apk_path = apk_path
    self._apk_name = os.path.splitext(os.path.basename(apk_path))[0]
    self._package_name = apk_helper.GetPackageName(self._apk_path)
    self._test_support_apk_path = test_support_apk_path

  def GetApkPath(self):
    """Returns the absolute path to the APK."""
    return self._apk_path

  def GetApkName(self):
    """Returns the name of the apk without the suffix."""
    return self._apk_name

  def GetPackageName(self):
    """Returns the package name of this APK."""
    return self._package_name

  # Override.
  def Install(self, device):
    device.Install(self.GetApkPath())
    if (self._test_support_apk_path and
        os.path.exists(self._test_support_apk_path)):
      device.Install(self._test_support_apk_path)

