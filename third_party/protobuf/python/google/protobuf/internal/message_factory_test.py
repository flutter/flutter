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

"""Tests for google.protobuf.message_factory."""

__author__ = 'matthewtoia@google.com (Matt Toia)'

import unittest
from google.protobuf import descriptor_pb2
from google.protobuf.internal import factory_test1_pb2
from google.protobuf.internal import factory_test2_pb2
from google.protobuf import descriptor_database
from google.protobuf import descriptor_pool
from google.protobuf import message_factory


class MessageFactoryTest(unittest.TestCase):

  def setUp(self):
    self.factory_test1_fd = descriptor_pb2.FileDescriptorProto.FromString(
        factory_test1_pb2.DESCRIPTOR.serialized_pb)
    self.factory_test2_fd = descriptor_pb2.FileDescriptorProto.FromString(
        factory_test2_pb2.DESCRIPTOR.serialized_pb)

  def _ExerciseDynamicClass(self, cls):
    msg = cls()
    msg.mandatory = 42
    msg.nested_factory_2_enum = 0
    msg.nested_factory_2_message.value = 'nested message value'
    msg.factory_1_message.factory_1_enum = 1
    msg.factory_1_message.nested_factory_1_enum = 0
    msg.factory_1_message.nested_factory_1_message.value = (
        'nested message value')
    msg.factory_1_message.scalar_value = 22
    msg.factory_1_message.list_value.extend(['one', 'two', 'three'])
    msg.factory_1_message.list_value.append('four')
    msg.factory_1_enum = 1
    msg.nested_factory_1_enum = 0
    msg.nested_factory_1_message.value = 'nested message value'
    msg.circular_message.mandatory = 1
    msg.circular_message.circular_message.mandatory = 2
    msg.circular_message.scalar_value = 'one deep'
    msg.scalar_value = 'zero deep'
    msg.list_value.extend(['four', 'three', 'two'])
    msg.list_value.append('one')
    msg.grouped.add()
    msg.grouped[0].part_1 = 'hello'
    msg.grouped[0].part_2 = 'world'
    msg.grouped.add(part_1='testing', part_2='123')
    msg.loop.loop.mandatory = 2
    msg.loop.loop.loop.loop.mandatory = 4
    serialized = msg.SerializeToString()
    converted = factory_test2_pb2.Factory2Message.FromString(serialized)
    reserialized = converted.SerializeToString()
    self.assertEquals(serialized, reserialized)
    result = cls.FromString(reserialized)
    self.assertEquals(msg, result)

  def testGetPrototype(self):
    db = descriptor_database.DescriptorDatabase()
    pool = descriptor_pool.DescriptorPool(db)
    db.Add(self.factory_test1_fd)
    db.Add(self.factory_test2_fd)
    factory = message_factory.MessageFactory()
    cls = factory.GetPrototype(pool.FindMessageTypeByName(
        'net.proto2.python.internal.Factory2Message'))
    self.assertIsNot(cls, factory_test2_pb2.Factory2Message)
    self._ExerciseDynamicClass(cls)
    cls2 = factory.GetPrototype(pool.FindMessageTypeByName(
        'net.proto2.python.internal.Factory2Message'))
    self.assertIs(cls, cls2)

  def testGetMessages(self):
    messages = message_factory.GetMessages([self.factory_test2_fd,
                                            self.factory_test1_fd])
    self.assertContainsSubset(
        ['net.proto2.python.internal.Factory2Message',
         'net.proto2.python.internal.Factory1Message'],
        messages.keys())
    self._ExerciseDynamicClass(
        messages['net.proto2.python.internal.Factory2Message'])

if __name__ == '__main__':
  unittest.main()
