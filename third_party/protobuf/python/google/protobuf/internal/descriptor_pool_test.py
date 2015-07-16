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

"""Tests for google.protobuf.descriptor_pool."""

__author__ = 'matthewtoia@google.com (Matt Toia)'

import unittest
from google.protobuf import descriptor_pb2
from google.protobuf.internal import factory_test1_pb2
from google.protobuf.internal import factory_test2_pb2
from google.protobuf import descriptor
from google.protobuf import descriptor_database
from google.protobuf import descriptor_pool


class DescriptorPoolTest(unittest.TestCase):

  def setUp(self):
    self.pool = descriptor_pool.DescriptorPool()
    self.factory_test1_fd = descriptor_pb2.FileDescriptorProto.FromString(
        factory_test1_pb2.DESCRIPTOR.serialized_pb)
    self.factory_test2_fd = descriptor_pb2.FileDescriptorProto.FromString(
        factory_test2_pb2.DESCRIPTOR.serialized_pb)
    self.pool.Add(self.factory_test1_fd)
    self.pool.Add(self.factory_test2_fd)

  def testFindFileByName(self):
    name1 = 'net/proto2/python/internal/factory_test1.proto'
    file_desc1 = self.pool.FindFileByName(name1)
    self.assertIsInstance(file_desc1, descriptor.FileDescriptor)
    self.assertEquals(name1, file_desc1.name)
    self.assertEquals('net.proto2.python.internal', file_desc1.package)
    self.assertIn('Factory1Message', file_desc1.message_types_by_name)

    name2 = 'net/proto2/python/internal/factory_test2.proto'
    file_desc2 = self.pool.FindFileByName(name2)
    self.assertIsInstance(file_desc2, descriptor.FileDescriptor)
    self.assertEquals(name2, file_desc2.name)
    self.assertEquals('net.proto2.python.internal', file_desc2.package)
    self.assertIn('Factory2Message', file_desc2.message_types_by_name)

  def testFindFileByNameFailure(self):
    try:
      self.pool.FindFileByName('Does not exist')
      self.fail('Expected KeyError')
    except KeyError:
      pass

  def testFindFileContainingSymbol(self):
    file_desc1 = self.pool.FindFileContainingSymbol(
        'net.proto2.python.internal.Factory1Message')
    self.assertIsInstance(file_desc1, descriptor.FileDescriptor)
    self.assertEquals('net/proto2/python/internal/factory_test1.proto',
                      file_desc1.name)
    self.assertEquals('net.proto2.python.internal', file_desc1.package)
    self.assertIn('Factory1Message', file_desc1.message_types_by_name)

    file_desc2 = self.pool.FindFileContainingSymbol(
        'net.proto2.python.internal.Factory2Message')
    self.assertIsInstance(file_desc2, descriptor.FileDescriptor)
    self.assertEquals('net/proto2/python/internal/factory_test2.proto',
                      file_desc2.name)
    self.assertEquals('net.proto2.python.internal', file_desc2.package)
    self.assertIn('Factory2Message', file_desc2.message_types_by_name)

  def testFindFileContainingSymbolFailure(self):
    try:
      self.pool.FindFileContainingSymbol('Does not exist')
      self.fail('Expected KeyError')
    except KeyError:
      pass

  def testFindMessageTypeByName(self):
    msg1 = self.pool.FindMessageTypeByName(
        'net.proto2.python.internal.Factory1Message')
    self.assertIsInstance(msg1, descriptor.Descriptor)
    self.assertEquals('Factory1Message', msg1.name)
    self.assertEquals('net.proto2.python.internal.Factory1Message',
                      msg1.full_name)
    self.assertEquals(None, msg1.containing_type)

    nested_msg1 = msg1.nested_types[0]
    self.assertEquals('NestedFactory1Message', nested_msg1.name)
    self.assertEquals(msg1, nested_msg1.containing_type)

    nested_enum1 = msg1.enum_types[0]
    self.assertEquals('NestedFactory1Enum', nested_enum1.name)
    self.assertEquals(msg1, nested_enum1.containing_type)

    self.assertEquals(nested_msg1, msg1.fields_by_name[
        'nested_factory_1_message'].message_type)
    self.assertEquals(nested_enum1, msg1.fields_by_name[
        'nested_factory_1_enum'].enum_type)

    msg2 = self.pool.FindMessageTypeByName(
        'net.proto2.python.internal.Factory2Message')
    self.assertIsInstance(msg2, descriptor.Descriptor)
    self.assertEquals('Factory2Message', msg2.name)
    self.assertEquals('net.proto2.python.internal.Factory2Message',
                      msg2.full_name)
    self.assertIsNone(msg2.containing_type)

    nested_msg2 = msg2.nested_types[0]
    self.assertEquals('NestedFactory2Message', nested_msg2.name)
    self.assertEquals(msg2, nested_msg2.containing_type)

    nested_enum2 = msg2.enum_types[0]
    self.assertEquals('NestedFactory2Enum', nested_enum2.name)
    self.assertEquals(msg2, nested_enum2.containing_type)

    self.assertEquals(nested_msg2, msg2.fields_by_name[
        'nested_factory_2_message'].message_type)
    self.assertEquals(nested_enum2, msg2.fields_by_name[
        'nested_factory_2_enum'].enum_type)

    self.assertTrue(msg2.fields_by_name['int_with_default'].has_default)
    self.assertEquals(
        1776, msg2.fields_by_name['int_with_default'].default_value)

    self.assertTrue(msg2.fields_by_name['double_with_default'].has_default)
    self.assertEquals(
        9.99, msg2.fields_by_name['double_with_default'].default_value)

    self.assertTrue(msg2.fields_by_name['string_with_default'].has_default)
    self.assertEquals(
        'hello world', msg2.fields_by_name['string_with_default'].default_value)

    self.assertTrue(msg2.fields_by_name['bool_with_default'].has_default)
    self.assertFalse(msg2.fields_by_name['bool_with_default'].default_value)

    self.assertTrue(msg2.fields_by_name['enum_with_default'].has_default)
    self.assertEquals(
        1, msg2.fields_by_name['enum_with_default'].default_value)

    msg3 = self.pool.FindMessageTypeByName(
        'net.proto2.python.internal.Factory2Message.NestedFactory2Message')
    self.assertEquals(nested_msg2, msg3)

  def testFindMessageTypeByNameFailure(self):
    try:
      self.pool.FindMessageTypeByName('Does not exist')
      self.fail('Expected KeyError')
    except KeyError:
      pass

  def testFindEnumTypeByName(self):
    enum1 = self.pool.FindEnumTypeByName(
        'net.proto2.python.internal.Factory1Enum')
    self.assertIsInstance(enum1, descriptor.EnumDescriptor)
    self.assertEquals(0, enum1.values_by_name['FACTORY_1_VALUE_0'].number)
    self.assertEquals(1, enum1.values_by_name['FACTORY_1_VALUE_1'].number)

    nested_enum1 = self.pool.FindEnumTypeByName(
        'net.proto2.python.internal.Factory1Message.NestedFactory1Enum')
    self.assertIsInstance(nested_enum1, descriptor.EnumDescriptor)
    self.assertEquals(
        0, nested_enum1.values_by_name['NESTED_FACTORY_1_VALUE_0'].number)
    self.assertEquals(
        1, nested_enum1.values_by_name['NESTED_FACTORY_1_VALUE_1'].number)

    enum2 = self.pool.FindEnumTypeByName(
        'net.proto2.python.internal.Factory2Enum')
    self.assertIsInstance(enum2, descriptor.EnumDescriptor)
    self.assertEquals(0, enum2.values_by_name['FACTORY_2_VALUE_0'].number)
    self.assertEquals(1, enum2.values_by_name['FACTORY_2_VALUE_1'].number)

    nested_enum2 = self.pool.FindEnumTypeByName(
        'net.proto2.python.internal.Factory2Message.NestedFactory2Enum')
    self.assertIsInstance(nested_enum2, descriptor.EnumDescriptor)
    self.assertEquals(
        0, nested_enum2.values_by_name['NESTED_FACTORY_2_VALUE_0'].number)
    self.assertEquals(
        1, nested_enum2.values_by_name['NESTED_FACTORY_2_VALUE_1'].number)

  def testFindEnumTypeByNameFailure(self):
    try:
      self.pool.FindEnumTypeByName('Does not exist')
      self.fail('Expected KeyError')
    except KeyError:
      pass

  def testUserDefinedDB(self):
    db = descriptor_database.DescriptorDatabase()
    self.pool = descriptor_pool.DescriptorPool(db)
    db.Add(self.factory_test1_fd)
    db.Add(self.factory_test2_fd)
    self.testFindMessageTypeByName()

if __name__ == '__main__':
  unittest.main()
