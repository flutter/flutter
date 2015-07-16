# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import logging
import os
import os.path

import mojo_unittest
import validation_test_interfaces_mojom

# pylint: disable=E0611
import mojo_system as system
from mojo_bindings import messaging
from mojo_tests import validation_util
from mopy.paths import Paths

logging.basicConfig(level=logging.ERROR)
paths = Paths()


class RoutingMessageReceiver(messaging.MessageReceiver):
  def __init__(self, request, response):
    self.request = request
    self.response = response

  def Accept(self, message):
    if message.header.is_response:
      return self.response.Accept(message)
    else:
      return self.request.Accept(message)


class SinkMessageReceiver(messaging.MessageReceiverWithResponder):

  def Accept(self, message):
    return False

  def AcceptWithResponder(self, message, responder):
    return False

  def Close(self):
    pass


class HandleMock(object):
  def IsValid(self):
    return True

  def Close(self):
    pass


class ValidationTest(mojo_unittest.MojoTestCase):

  @staticmethod
  def ParseData(data_dir, filename):
    data = validation_util.ParseData(
        open(os.path.join(data_dir, filename), 'r').read())
    expect_file = filename[:-4] + 'expected'
    expected_error = open(
        os.path.join(data_dir, expect_file), 'r').read().strip();
    success = expected_error == 'PASS'
    return (filename, data, success)

  @staticmethod
  def GetData(prefix):
    data_dir = os.path.join(paths.src_root, 'mojo', 'public', 'interfaces',
                            'bindings', 'tests', 'data', 'validation')

    # TODO(yzshen): Skip some interface versioning tests.
    skipped_tests = ["conformance_mthd13_good_2.data"]

    return [ValidationTest.ParseData(data_dir, x) for x in os.listdir(data_dir)
            if x.startswith(prefix) and x.endswith('.data') and
               x not in skipped_tests]

  def runTest(self, prefix, message_receiver):
    for (filename, data, expected) in ValidationTest.GetData(prefix):
      self.assertEquals(len(data.error_message), 0)
      handles = [HandleMock() for _ in xrange(data.num_handles)]
      message = messaging.Message(data.data, handles)
      self.assertEquals(message_receiver.Accept(message), expected,
                        'Unexpected result for test: %s' % filename)

  def testConformance(self):
    manager = validation_test_interfaces_mojom.ConformanceTestInterface.manager
    proxy = manager._InternalProxy(SinkMessageReceiver(), None, 0)
    stub = manager._Stub(proxy)
    self.runTest('conformance_', stub)
