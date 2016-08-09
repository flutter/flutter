#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A simple host test module.

This module runs on the host machine and is responsible for creating 2
task machines, waiting for them, and running RPC calls on them.
"""

import argparse
import logging
import os
import sys
import time

# Map the testing directory so we can import legion.legion_test.
TESTING_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    '..', '..', '..', '..', 'testing')
sys.path.append(TESTING_DIR)

from legion import legion_test_case


class ExampleTestController(legion_test_case.TestCase):
  """A simple example controller for a test."""

  @classmethod
  def CreateTestTask(cls):
    """Create a new task."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--task-hash')
    parser.add_argument('--os', default='Ubuntu-14.04')
    args, _ = parser.parse_known_args()

    task = cls.CreateTask(
        isolated_hash=args.task_hash,
        dimensions={'os': args.os},
        idle_timeout_secs=90,
        connection_timeout_secs=90,
        verbosity=logging.DEBUG)
    task.Create()
    return task

  @classmethod
  def setUpClass(cls):
    """Creates the task machines and waits until they connect."""
    cls.task1 = cls.CreateTestTask()
    cls.task2 = cls.CreateTestTask()
    cls.task1.WaitForConnection()
    cls.task2.WaitForConnection()

  def testCallEcho(self):
    """Tests rpc.Echo on a task."""
    logging.info('Calling Echo on %s', self.task2.name)
    self.assertEqual(self.task2.rpc.Echo('foo'), 'echo foo')

  def testLaunchTaskBinary(self):
    """Call task_test.py 'name' on the tasks."""
    self.VerifyTaskBinaryLaunched(self.task1)
    self.VerifyTaskBinaryLaunched(self.task2)

  def VerifyTaskBinaryLaunched(self, task):
    logging.info(
        'Calling Process to run "./task_test.py %s"', task.name)
    proc = task.Process(['./task_test.py', task.name])
    proc.Wait()
    self.assertEqual(proc.GetReturncode(), 0)
    self.assertIn(task.name, proc.ReadStdout())
    self.assertEquals(proc.ReadStderr(), '')
    proc.Delete()


if __name__ == '__main__':
  legion_test_case.main()
