# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Defines the test controller base library.

This module is the basis on which test controllers are built and executed.
"""

import logging
import sys

#pylint: disable=relative-import
import common_lib
import task_controller
import task_registration_server


class TestController(object):
  """The base test controller class."""

  def __init__(self):
    self._registration_server = (
        task_registration_server.TaskRegistrationServer())

  def SetUp(self):
    """Setup method used by the subclass."""
    pass

  def RunTest(self):
    """Main test method used by the subclass."""
    raise NotImplementedError()

  def TearDown(self):
    """Teardown method used by the subclass."""
    pass

  def CreateNewTask(self, *args, **kwargs):
    task = task_controller.TaskController(*args, **kwargs)
    self._registration_server.RegisterTaskCallback(
        task.otp, task.OnConnect)
    return task

  def RunController(self):
    """Main entry point for the controller."""
    print ' '.join(sys.argv)
    common_lib.InitLogging()
    self._registration_server.Start()

    error = None
    tb = None
    try:
      self.SetUp()
      self.RunTest()
    except Exception as e:
      # Defer raising exceptions until after TearDown is called.
      error = e
      tb = sys.exc_info()[-1]
    try:
      self.TearDown()
    except Exception as e:
      if not tb:
        error = e
        tb = sys.exc_info()[-1]

    self._registration_server.Shutdown()
    task_controller.TaskController.ReleaseAllTasks()
    if error:
      raise error, None, tb  #pylint: disable=raising-bad-type
