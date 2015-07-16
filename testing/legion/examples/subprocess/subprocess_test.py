#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A host test module demonstrating interacting with remote subprocesses."""

import argparse
import logging
import os
import sys
import time
import xmlrpclib

# Map the testing directory so we can import legion.legion_test.
TESTING_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    '..', '..', '..', '..', 'testing')
sys.path.append(TESTING_DIR)

from legion import legion_test_case


class ExampleTestController(legion_test_case.TestCase):
  """An example controller using the remote subprocess functions."""

  @classmethod
  def setUpClass(cls):
    """Creates the task machine and waits until it connects."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--task-hash')
    parser.add_argument('--os', default='Ubuntu-14.04')
    args, _ = parser.parse_known_args()

    cls.task = cls.CreateTask(
        isolated_hash=args.task_hash,
        dimensions={'os': args.os},
        idle_timeout_secs=90,
        connection_timeout_secs=90,
        verbosity=logging.DEBUG)
    cls.task.Create()
    cls.task.WaitForConnection()

  def testMultipleProcesses(self):
    """Tests that processes can be run and controlled simultaneously."""
    start = time.time()
    logging.info('Starting "sleep 10" and "sleep 20"')
    sleep10 = self.task.Process(['sleep', '10'])
    sleep20 = self.task.Process(['sleep', '20'])

    logging.info('Waiting for sleep 10 to finish and verifying timing')
    sleep10.Wait()
    elapsed = time.time() - start
    self.assertGreaterEqual(elapsed, 10)
    self.assertLess(elapsed, 11)

    logging.info('Waiting for sleep 20 to finish and verifying timing')
    sleep20.Wait()
    elapsed = time.time() - start
    self.assertGreaterEqual(elapsed, 20)

    sleep10.Delete()
    sleep20.Delete()

  def testTerminate(self):
    """Tests that a process can be correctly terminated."""
    start = time.time()

    logging.info('Starting "sleep 20"')
    sleep20 = self.task.Process(['sleep', '20'])
    logging.info('Calling Terminate()')
    sleep20.Terminate()
    try:
      logging.info('Trying to wait for sleep 20 to complete')
      sleep20.Wait()
    except xmlrpclib.Fault:
      pass
    finally:
      sleep20.Delete()
    logging.info('Checking to make sure sleep 20 was actually terminated')
    self.assertLess(time.time() - start, 20)

  def testLs(self):
    """Tests that the returned results from a process are correct."""
    logging.info('Calling "ls"')
    ls = self.task.Process(['ls'])
    logging.info('Trying to wait for ls to complete')
    ls.Wait()
    logging.info('Checking that ls completed and returned the correct results')
    self.assertEqual(ls.GetReturncode(), 0)
    self.assertIn('task.isolate', ls.ReadStdout())


if __name__ == '__main__':
  legion_test_case.main()
