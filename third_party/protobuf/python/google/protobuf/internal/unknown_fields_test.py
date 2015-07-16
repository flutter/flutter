#! /usr/bin/python
# -*- coding: utf-8 -*-
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

"""Test for preservation of unknown fields in the pure Python implementation."""

__author__ = 'bohdank@google.com (Bohdan Koval)'

import unittest
from google.protobuf import unittest_mset_pb2
from google.protobuf import unittest_pb2
from google.protobuf.internal import encoder
from google.protobuf.internal import test_util
from google.protobuf.internal import type_checkers


class UnknownFieldsTest(unittest.TestCase):

  def setUp(self):
    self.descriptor = unittest_pb2.TestAllTypes.DESCRIPTOR
    self.all_fields = unittest_pb2.TestAllTypes()
    test_util.SetAllFields(self.all_fields)
    self.all_fields_data = self.all_fields.SerializeToString()
    self.empty_message = unittest_pb2.TestEmptyMessage()
    self.empty_message.ParseFromString(self.all_fields_data)
    self.unknown_fields = self.empty_message._unknown_fields

  def GetField(self, name):
    field_descriptor = self.descriptor.fields_by_name[name]
    wire_type = type_checkers.FIELD_TYPE_TO_WIRE_TYPE[field_descriptor.type]
    field_tag = encoder.TagBytes(field_descriptor.number, wire_type)
    for tag_bytes, value in self.unknown_fields:
      if tag_bytes == field_tag:
        decoder = unittest_pb2.TestAllTypes._decoders_by_tag[tag_bytes]
        result_dict = {}
        decoder(value, 0, len(value), self.all_fields, result_dict)
        return result_dict[field_descriptor]

  def testVarint(self):
    value = self.GetField('optional_int32')
    self.assertEqual(self.all_fields.optional_int32, value)

  def testFixed32(self):
    value = self.GetField('optional_fixed32')
    self.assertEqual(self.all_fields.optional_fixed32, value)

  def testFixed64(self):
    value = self.GetField('optional_fixed64')
    self.assertEqual(self.all_fields.optional_fixed64, value)

  def testLengthDelimited(self):
    value = self.GetField('optional_string')
    self.assertEqual(self.all_fields.optional_string, value)

  def testGroup(self):
    value = self.GetField('optionalgroup')
    self.assertEqual(self.all_fields.optionalgroup, value)

  def testSerialize(self):
    data = self.empty_message.SerializeToString()

    # Don't use assertEqual because we don't want to dump raw binary data to
    # stdout.
    self.assertTrue(data == self.all_fields_data)

  def testCopyFrom(self):
    message = unittest_pb2.TestEmptyMessage()
    message.CopyFrom(self.empty_message)
    self.assertEqual(self.unknown_fields, message._unknown_fields)

  def testMergeFrom(self):
    message = unittest_pb2.TestAllTypes()
    message.optional_int32 = 1
    message.optional_uint32 = 2
    source = unittest_pb2.TestEmptyMessage()
    source.ParseFromString(message.SerializeToString())

    message.ClearField('optional_int32')
    message.optional_int64 = 3
    message.optional_uint32 = 4
    destination = unittest_pb2.TestEmptyMessage()
    destination.ParseFromString(message.SerializeToString())
    unknown_fields = destination._unknown_fields[:]

    destination.MergeFrom(source)
    self.assertEqual(unknown_fields + source._unknown_fields,
                     destination._unknown_fields)

  def testClear(self):
    self.empty_message.Clear()
    self.assertEqual(0, len(self.empty_message._unknown_fields))

  def testByteSize(self):
    self.assertEqual(self.all_fields.ByteSize(), self.empty_message.ByteSize())

  def testUnknownExtensions(self):
    message = unittest_pb2.TestEmptyMessageWithExtensions()
    message.ParseFromString(self.all_fields_data)
    self.assertEqual(self.empty_message._unknown_fields,
                     message._unknown_fields)

  def testListFields(self):
    # Make sure ListFields doesn't return unknown fields.
    self.assertEqual(0, len(self.empty_message.ListFields()))

  def testSerializeMessageSetWireFormatUnknownExtension(self):
    # Create a message using the message set wire format with an unknown
    # message.
    raw = unittest_mset_pb2.RawMessageSet()

    # Add an unknown extension.
    item = raw.item.add()
    item.type_id = 1545009
    message1 = unittest_mset_pb2.TestMessageSetExtension1()
    message1.i = 12345
    item.message = message1.SerializeToString()

    serialized = raw.SerializeToString()

    # Parse message using the message set wire format.
    proto = unittest_mset_pb2.TestMessageSet()
    proto.MergeFromString(serialized)

    # Verify that the unknown extension is serialized unchanged
    reserialized = proto.SerializeToString()
    new_raw = unittest_mset_pb2.RawMessageSet()
    new_raw.MergeFromString(reserialized)
    self.assertEqual(raw, new_raw)

  def testEquals(self):
    message = unittest_pb2.TestEmptyMessage()
    message.ParseFromString(self.all_fields_data)
    self.assertEqual(self.empty_message, message)

    self.all_fields.ClearField('optional_string')
    message.ParseFromString(self.all_fields.SerializeToString())
    self.assertNotEqual(self.empty_message, message)


if __name__ == '__main__':
  unittest.main()
