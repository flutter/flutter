# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

import mojo_unittest
from mojo_bindings import messaging

# pylint: disable=E0611
import mojo_system as system


class _ForwardingConnectionErrorHandler(messaging.ConnectionErrorHandler):

  def __init__(self, callback):
    messaging.ConnectionErrorHandler.__init__(self)
    self._callback = callback

  def OnError(self, result):
    self._callback(result)


class ConnectorTest(mojo_unittest.MojoTestCase):

  def setUp(self):
    super(ConnectorTest, self).setUp()
    self.received_messages = []
    self.received_errors = []
    def _OnMessage(message):
      self.received_messages.append(message)
      return True
    def _OnError(result):
      self.received_errors.append(result)
    handles = system.MessagePipe()
    self.connector = messaging.Connector(handles.handle1)
    self.connector.SetIncomingMessageReceiver(
        messaging.ForwardingMessageReceiver(_OnMessage))
    self.connector.SetErrorHandler(
        _ForwardingConnectionErrorHandler(_OnError))
    self.connector.Start()
    self.handle = handles.handle0


  def tearDown(self):
    self.connector = None
    self.handle = None
    self.received_messages = []
    self.received_errors = []
    super(ConnectorTest, self).tearDown()

  def testConnectorRead(self):
    self.handle.WriteMessage()
    self.loop.RunUntilIdle()
    self.assertTrue(self.received_messages)
    self.assertFalse(self.received_errors)

  def testConnectorWrite(self):
    self.connector.Accept(messaging.Message())
    (result, _, _) = self.handle.ReadMessage()
    self.assertEquals(result, system.RESULT_OK)
    self.assertFalse(self.received_errors)

  def testConnectorCloseRemoteHandle(self):
    self.handle.Close()
    self.loop.RunUntilIdle()
    self.assertFalse(self.received_messages)
    self.assertTrue(self.received_errors)
    self.assertEquals(self.received_errors[0],
                      system.RESULT_FAILED_PRECONDITION)

  def testConnectorDeleteConnector(self):
    self.connector = None
    (result, _, _) = self.handle.ReadMessage()
    self.assertEquals(result, system.RESULT_FAILED_PRECONDITION)

  def testConnectorWriteHandle(self):
    new_handles = system.MessagePipe()
    self.handle.WriteMessage(None, [new_handles.handle0])
    self.loop.RunUntilIdle()
    self.assertTrue(self.received_messages)
    self.assertTrue(self.received_messages[0].handles)
    self.assertFalse(self.received_errors)


class HeaderTest(unittest.TestCase):

  def testSimpleMessageHeader(self):
    header = messaging.MessageHeader(0xdeadbeaf, messaging.NO_FLAG)
    self.assertEqual(header.message_type, 0xdeadbeaf)
    self.assertFalse(header.has_request_id)
    self.assertFalse(header.expects_response)
    self.assertFalse(header.is_response)
    data = header.Serialize()
    other_header = messaging.MessageHeader.Deserialize(data)
    self.assertEqual(other_header.message_type, 0xdeadbeaf)
    self.assertFalse(other_header.has_request_id)
    self.assertFalse(other_header.expects_response)
    self.assertFalse(other_header.is_response)

  def testMessageHeaderWithRequestID(self):
    # Request message.
    header = messaging.MessageHeader(0xdeadbeaf,
                                     messaging.MESSAGE_EXPECTS_RESPONSE_FLAG)

    self.assertEqual(header.message_type, 0xdeadbeaf)
    self.assertTrue(header.has_request_id)
    self.assertTrue(header.expects_response)
    self.assertFalse(header.is_response)
    self.assertEqual(header.request_id, 0)

    data = header.Serialize()
    other_header = messaging.MessageHeader.Deserialize(data)

    self.assertEqual(other_header.message_type, 0xdeadbeaf)
    self.assertTrue(other_header.has_request_id)
    self.assertTrue(other_header.expects_response)
    self.assertFalse(other_header.is_response)
    self.assertEqual(other_header.request_id, 0)

    header.request_id = 0xdeadbeafdeadbeaf
    data = header.Serialize()
    other_header = messaging.MessageHeader.Deserialize(data)

    self.assertEqual(other_header.request_id, 0xdeadbeafdeadbeaf)

    # Response message.
    header = messaging.MessageHeader(0xdeadbeaf,
                                     messaging.MESSAGE_IS_RESPONSE_FLAG,
                                     0xdeadbeafdeadbeaf)

    self.assertEqual(header.message_type, 0xdeadbeaf)
    self.assertTrue(header.has_request_id)
    self.assertFalse(header.expects_response)
    self.assertTrue(header.is_response)
    self.assertEqual(header.request_id, 0xdeadbeafdeadbeaf)

    data = header.Serialize()
    other_header = messaging.MessageHeader.Deserialize(data)

    self.assertEqual(other_header.message_type, 0xdeadbeaf)
    self.assertTrue(other_header.has_request_id)
    self.assertFalse(other_header.expects_response)
    self.assertTrue(other_header.is_response)
    self.assertEqual(other_header.request_id, 0xdeadbeafdeadbeaf)


class RouterTest(mojo_unittest.MojoTestCase):

  def setUp(self):
    super(RouterTest, self).setUp()
    self.received_messages = []
    self.received_errors = []
    def _OnMessage(message):
      self.received_messages.append(message)
      return True
    def _OnError(result):
      self.received_errors.append(result)
    handles = system.MessagePipe()
    self.router = messaging.Router(handles.handle1)
    self.router.SetIncomingMessageReceiver(
        messaging.ForwardingMessageReceiver(_OnMessage))
    self.router.SetErrorHandler(
        _ForwardingConnectionErrorHandler(_OnError))
    self.router.Start()
    self.handle = handles.handle0

  def tearDown(self):
    self.router = None
    self.handle = None
    super(RouterTest, self).tearDown()

  def testSimpleMessage(self):
    header_data = messaging.MessageHeader(0, messaging.NO_FLAG).Serialize()
    message = messaging.Message(header_data)
    self.router.Accept(message)
    self.loop.RunUntilIdle()
    self.assertFalse(self.received_errors)
    self.assertFalse(self.received_messages)
    (res, data, _) = self.handle.ReadMessage(bytearray(len(header_data)))
    self.assertEquals(system.RESULT_OK, res)
    self.assertEquals(data[0], header_data)

  def testSimpleReception(self):
    header_data = messaging.MessageHeader(0, messaging.NO_FLAG).Serialize()
    self.handle.WriteMessage(header_data)
    self.loop.RunUntilIdle()
    self.assertFalse(self.received_errors)
    self.assertEquals(len(self.received_messages), 1)
    self.assertEquals(self.received_messages[0].data, header_data)

  def testRequestResponse(self):
    header_data = messaging.MessageHeader(
        0, messaging.MESSAGE_EXPECTS_RESPONSE_FLAG).Serialize()
    message = messaging.Message(header_data)
    back_messages = []
    def OnBackMessage(message):
      back_messages.append(message)
      return True
    self.router.AcceptWithResponder(message,
                                    messaging.ForwardingMessageReceiver(
                                        OnBackMessage))
    self.loop.RunUntilIdle()
    self.assertFalse(self.received_errors)
    self.assertFalse(self.received_messages)
    (res, data, _) = self.handle.ReadMessage(bytearray(len(header_data)))
    self.assertEquals(system.RESULT_OK, res)
    message_header = messaging.MessageHeader.Deserialize(data[0])
    self.assertNotEquals(message_header.request_id, 0)
    response_header_data = messaging.MessageHeader(
        0,
        messaging.MESSAGE_IS_RESPONSE_FLAG,
        message_header.request_id).Serialize()
    self.handle.WriteMessage(response_header_data)
    self.loop.RunUntilIdle()
    self.assertFalse(self.received_errors)
    self.assertEquals(len(back_messages), 1)
    self.assertEquals(back_messages[0].data, response_header_data)
