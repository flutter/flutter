# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import json
import logging

from pylib import constants
from pylib.base import test_instance
from pylib.utils import apk_helper

class UirobotTestInstance(test_instance.TestInstance):

  def __init__(self, args, error_func):
    """Constructor.

    Args:
      args: Command line arguments.
    """
    super(UirobotTestInstance, self).__init__()
    if not args.app_under_test:
      error_func('Must set --app-under-test.')
    self._app_under_test = args.app_under_test
    self._minutes = args.minutes

    if args.remote_device_file:
      with open(args.remote_device_file) as remote_device_file:
        device_json = json.load(remote_device_file)
    else:
      device_json = {}
    device_type = device_json.get('device_type', 'Android')
    if args.device_type:
      if device_type and device_type != args.device_type:
        logging.info('Overriding device_type from %s to %s',
                     device_type, args.device_type)
      device_type = args.device_type

    if device_type == 'Android':
      self._suite = 'Android Uirobot'
      self._package_name = apk_helper.GetPackageName(self._app_under_test)
    elif device_type == 'iOS':
      self._suite = 'iOS Uirobot'
      self._package_name = self._app_under_test


  #override
  def TestType(self):
    """Returns type of test."""
    return 'uirobot'

  #override
  def SetUp(self):
    """Setup for test."""
    pass

  #override
  def TearDown(self):
    """Teardown for test."""
    pass

  @property
  def app_under_test(self):
    """Returns the app to run the test on."""
    return self._app_under_test

  @property
  def minutes(self):
    """Returns the number of minutes to run the uirobot for."""
    return self._minutes

  @property
  def package_name(self):
    """Returns the name of the package in the APK."""
    return self._package_name

  @property
  def suite(self):
    return self._suite
