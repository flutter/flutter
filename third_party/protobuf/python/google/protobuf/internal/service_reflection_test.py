#! /usr/bin/python
#
# Protocol Buffers - Google's data interchange format
# Copyright 2008 Google Inc.  All rights reserved.
# http://code.google.com/p/protobuf/
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Tests for google.protobuf.internal.service_reflection."""

__author__ = 'petar@google.com (Petar Petrov)'

import unittest
from google.protobuf import unittest_pb2
from google.protobuf import service_reflection
from google.protobuf import service


class FooUnitTest(unittest.TestCase):

  def testService(self):
    class MockRpcChannel(service.RpcChannel):
      def CallMethod(self, method, controller, request, response, callback):
        self.method = method
        self.controller = controller
        self.request = request
        callback(response)

    class MockRpcController(service.RpcController):
      def SetFailed(self, msg):
        self.failure_message = msg

    self.callback_response = None

    class MyService(unittest_pb2.TestService):
      pass

    self.callback_response = None

    def MyCallback(response):
      self.callback_response = response

    rpc_controller = MockRpcController()
    channel = MockRpcChannel()
    srvc = MyService()
    srvc.Foo(rpc_controller, unittest_pb2.FooRequest(), MyCallback)
    self.assertEqual('Method Foo not implemented.',
                     rpc_controller.failure_message)
    self.assertEqual(None, self.callback_response)

    rpc_controller.failure_message = None

    service_descriptor = unittest_pb2.TestService.GetDescriptor()
    srvc.CallMethod(service_descriptor.methods[1], rpc_controller,
                    unittest_pb2.BarRequest(), MyCallback)
    self.assertEqual('Method Bar not implemented.',
                     rpc_controller.failure_message)
    self.assertEqual(None, self.callback_response)
    
    class MyServiceImpl(unittest_pb2.TestService):
      def Foo(self, rpc_controller, request, done):
        self.foo_called = True
      def Bar(self, rpc_controller, request, done):
        self.bar_called = True

    srvc = MyServiceImpl()
    rpc_controller.failure_message = None
    srvc.Foo(rpc_controller, unittest_pb2.FooRequest(), MyCallback)
    self.assertEqual(None, rpc_controller.failure_message)
    self.assertEqual(True, srvc.foo_called)

    rpc_controller.failure_message = None
    srvc.CallMethod(service_descriptor.methods[1], rpc_controller,
                    unittest_pb2.BarRequest(), MyCallback)
    self.assertEqual(None, rpc_controller.failure_message)
    self.assertEqual(True, srvc.bar_called)

  def testServiceStub(self):
    class MockRpcChannel(service.RpcChannel):
      def CallMethod(self, method, controller, request,
                     response_class, callback):
        self.method = method
        self.controller = controller
        self.request = request
        callback(response_class())

    self.callback_response = None

    def MyCallback(response):
      self.callback_response = response

    channel = MockRpcChannel()
    stub = unittest_pb2.TestService_Stub(channel)
    rpc_controller = 'controller'
    request = 'request'

    # GetDescriptor now static, still works as instance method for compatability
    self.assertEqual(unittest_pb2.TestService_Stub.GetDescriptor(),
                     stub.GetDescriptor())

    # Invoke method.
    stub.Foo(rpc_controller, request, MyCallback)

    self.assertTrue(isinstance(self.callback_response,
                               unittest_pb2.FooResponse))
    self.assertEqual(request, channel.request)
    self.assertEqual(rpc_controller, channel.controller)
    self.assertEqual(stub.GetDescriptor().methods[0], channel.method)


if __name__ == '__main__':
  unittest.main()
