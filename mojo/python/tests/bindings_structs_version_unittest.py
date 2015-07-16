# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import math
import unittest

import mojo_unittest

# pylint: disable=E0611,F0401
import mojo_bindings.serialization as serialization
import mojo_system

# Generated files
# pylint: disable=F0401
import rect_mojom
import test_structs_mojom


class StructVersionBindingsTest(mojo_unittest.MojoTestCase):

  def SerializeAndDeserialize(self, target_class, input_instance):
    (data, handles) = input_instance.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    return target_class.Deserialize(context)

  def MakeRect(self, factor):
    return rect_mojom.Rect(
        x=factor, y=2*factor, width=10*factor, height=20*factor)

  def testOldToNew(self):
    v0 = test_structs_mojom.MultiVersionStructV0()
    v0.f_int32 = 123
    expected = test_structs_mojom.MultiVersionStruct()
    expected.f_int32 = 123

    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStruct, v0)
    self.assertEquals(output, expected)

    v1 = test_structs_mojom.MultiVersionStructV1()
    v1.f_int32 = 123
    v1.f_rect = self.MakeRect(5)
    expected = test_structs_mojom.MultiVersionStruct()
    expected.f_int32 = 123
    expected.f_rect = self.MakeRect(5)

    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStruct, v1)
    self.assertEquals(output, expected)

    v3 = test_structs_mojom.MultiVersionStructV3()
    v3.f_int32 = 123
    v3.f_rect = self.MakeRect(5)
    v3.f_string = 'hello'
    expected = test_structs_mojom.MultiVersionStruct()
    expected.f_int32 = 123
    expected.f_rect = self.MakeRect(5)
    expected.f_string = 'hello'

    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStruct, v3)
    self.assertEquals(output, expected)

    v5 = test_structs_mojom.MultiVersionStructV5()
    v5.f_int32 = 123
    v5.f_rect = self.MakeRect(5)
    v5.f_string = 'hello'
    v5.f_array = [10, 9, 8]
    expected = test_structs_mojom.MultiVersionStruct()
    expected.f_int32 = 123
    expected.f_rect = self.MakeRect(5)
    expected.f_string = 'hello'
    expected.f_array = [10, 9, 8]

    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStruct, v5)
    self.assertEquals(output, expected)

    pipe = mojo_system.MessagePipe()
    v7 = test_structs_mojom.MultiVersionStructV7()
    v7.f_int32 = 123
    v7.f_rect = self.MakeRect(5)
    v7.f_string = 'hello'
    v7.f_array = [10, 9, 8]
    v7.f_message_pipe = pipe.handle0
    v7.f_bool = True
    expected = test_structs_mojom.MultiVersionStruct()
    expected.f_int32 = 123
    expected.f_rect = self.MakeRect(5)
    expected.f_string = 'hello'
    expected.f_array = [10, 9, 8]
    expected.f_message_pipe = pipe.handle0
    expected.f_bool = True

    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStruct, v7)
    self.assertEquals(output, expected)

  def testNewToNew(self):
    pipe = mojo_system.MessagePipe()
    input_struct = test_structs_mojom.MultiVersionStruct()
    input_struct.f_int32 = 123
    input_struct.f_rect = self.MakeRect(5)
    input_struct.f_string = 'hello'
    input_struct.f_array = [10, 9, 8]
    input_struct.f_message_pipe = pipe.handle0
    input_struct.f_bool = True
    input_struct.f_int16 = 256

    expected = test_structs_mojom.MultiVersionStructV7()
    expected.f_int32 = 123
    expected.f_rect = self.MakeRect(5)
    expected.f_string = 'hello'
    expected.f_array = [10, 9, 8]
    expected.f_message_pipe = pipe.handle0
    expected.f_bool = True
    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStructV7, input_struct)
    self.assertEquals(output, expected)

    expected = test_structs_mojom.MultiVersionStructV5()
    expected.f_int32 = 123
    expected.f_rect = self.MakeRect(5)
    expected.f_string = 'hello'
    expected.f_array = [10, 9, 8]
    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStructV5, input_struct)
    self.assertEquals(output, expected)

    expected = test_structs_mojom.MultiVersionStructV3()
    expected.f_int32 = 123
    expected.f_rect = self.MakeRect(5)
    expected.f_string = 'hello'
    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStructV3, input_struct)
    self.assertEquals(output, expected)

    expected = test_structs_mojom.MultiVersionStructV1()
    expected.f_int32 = 123
    expected.f_rect = self.MakeRect(5)
    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStructV1, input_struct)
    self.assertEquals(output, expected)

    expected = test_structs_mojom.MultiVersionStructV0()
    expected.f_int32 = 123
    output = self.SerializeAndDeserialize(
        test_structs_mojom.MultiVersionStructV0, input_struct)
    self.assertEquals(output, expected)
