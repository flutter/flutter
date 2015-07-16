# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Adds unittest-esque functionality to Legion."""

import argparse
import logging
import sys
import unittest

#pylint: disable=relative-import
import common_lib
import task_controller
import task_registration_server

BANNER_WIDTH = 80


class TestCase(unittest.TestCase):
  """Test case class with added Legion support."""

  _registration_server = None
  _initialized = False

  @classmethod
  def __new__(cls, *args, **kwargs):
    """Initialize the class and return a new instance."""
    cls._InitializeClass()
    return super(TestCase, cls).__new__(*args, **kwargs)

  def __init__(self, test_name='runTest'):
    super(TestCase, self).__init__(test_name)
    method = getattr(self, test_name, None)
    if method:
      # Install the _RunTest method
      self._TestMethod = method
      setattr(self, test_name, self._RunTest)

  def _RunTest(self):
    """Runs the test method and provides banner info and error reporting."""
    self._LogInfoBanner(self._testMethodName, self.shortDescription())
    try:
      return self._TestMethod()
    except:
      exc_info = sys.exc_info()
      logging.error('', exc_info=exc_info)
      raise exc_info[0], exc_info[1], exc_info[2]

  @classmethod
  def _InitializeClass(cls):
    """Handles class level initialization.

    There are 2 types of setup/teardown methods that always need to be run:
    1) Framework level setup/teardown
    2) Test case level setup/teardown

    This method installs handlers in place of setUpClass and tearDownClass that
    will ensure both types of setup/teardown methods are called correctly.
    """
    if cls._initialized:
      return
    cls._OriginalSetUpClassMethod = cls.setUpClass
    cls.setUpClass = cls._HandleSetUpClass
    cls._OriginalTearDownClassMethod = cls.tearDownClass
    cls.tearDownClass = cls._HandleTearDownClass
    cls._initialized = True

  @classmethod
  def _LogInfoBanner(cls, method_name, method_doc=None):
    """Formats and logs test case information."""
    logging.info('*' * BANNER_WIDTH)
    logging.info(method_name.center(BANNER_WIDTH))
    if method_doc:
      for line in method_doc.split('\n'):
        logging.info(line.center(BANNER_WIDTH))
    logging.info('*' * BANNER_WIDTH)

  @classmethod
  def CreateTask(cls, *args, **kwargs):
    """Convenience method to create a new task."""
    task = task_controller.TaskController(*args, **kwargs)
    cls._registration_server.RegisterTaskCallback(
        task.otp, task.OnConnect)
    return task

  @classmethod
  def _SetUpFramework(cls):
    """Perform the framework-specific setup operations."""
    cls._registration_server = (
        task_registration_server.TaskRegistrationServer())
    cls._registration_server.Start()

  @classmethod
  def _TearDownFramework(cls):
    """Perform the framework-specific teardown operations."""
    if cls._registration_server:
      cls._registration_server.Shutdown()
    task_controller.TaskController.ReleaseAllTasks()

  @classmethod
  def _HandleSetUpClass(cls):
    """Performs common class-level setup operations.

    This method performs test-wide setup such as starting the registration
    server and then calls the original setUpClass method."""
    try:
      common_lib.InitLogging()
      cls._LogInfoBanner('setUpClass', 'Performs class level setup.')
      cls._SetUpFramework()
      cls._OriginalSetUpClassMethod()
    except:
      # Make sure we tear down in case of any exceptions
      cls._HandleTearDownClass(setup_failed=True)
      exc_info = sys.exc_info()
      logging.error('', exc_info=exc_info)
      raise exc_info[0], exc_info[1], exc_info[2]

  @classmethod
  def _HandleTearDownClass(cls, setup_failed=False):
    """Performs common class-level tear down operations.

    This method calls the original tearDownClass then performs test-wide
    tear down such as stopping the registration server.
    """
    cls._LogInfoBanner('tearDownClass', 'Performs class level tear down.')
    try:
      if not setup_failed:
        cls._OriginalTearDownClassMethod()
    finally:
      cls._TearDownFramework()


def main():
  unittest.main(verbosity=0, argv=sys.argv[:1])
