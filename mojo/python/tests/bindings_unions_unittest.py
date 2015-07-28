# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import struct
import unittest

# Generated files
# pylint: disable=F0401
import test_unions_mojom
import mojo_bindings.serialization as serialization

class UnionBindingsTest(unittest.TestCase):

  def testBasics(self):
    u = test_unions_mojom.PodUnion()
    self.assertTrue(u.IsUnknown())

    u.f_uint32 = 32
    self.assertEquals(u.f_uint32, 32)
    self.assertEquals(u.data, 32)
    self.assertEquals(test_unions_mojom.PodUnion.Tags.f_uint32, u.tag)
    self.assertFalse(u.IsUnknown())

    u = test_unions_mojom.PodUnion(f_uint8=8)
    self.assertEquals(u.f_uint8, 8)
    self.assertEquals(u.data, 8)
    self.assertEquals(test_unions_mojom.PodUnion.Tags.f_uint8, u.tag)

    with self.assertRaises(TypeError):
      test_unions_mojom.PodUnion(f_uint8=8, f_int16=10)

    with self.assertRaises(AttributeError):
      test_unions_mojom.PodUnion(bad_field=10)

    with self.assertRaises(AttributeError):
      u = test_unions_mojom.PodUnion()
      u.bad_field = 32

    with self.assertRaises(AttributeError):
      _ = u.f_uint16

  def testPodUnionSerialization(self):
    u = test_unions_mojom.PodUnion(f_uint32=32)
    (data, handles) = u.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.PodUnion.Deserialize(context)

    self.assertFalse(decoded.IsUnknown())
    self.assertEquals(u, decoded)

  def testUnionUnknownTag(self):
    u = test_unions_mojom.NewUnion(f_int16=10)
    (data, handles) = u.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.OldUnion.Deserialize(context)

    self.assertTrue(decoded.IsUnknown())

  def testObjectInUnionSerialization(self):
    u = test_unions_mojom.ObjectUnion(
        f_dummy=test_unions_mojom.DummyStruct())
    u.f_dummy.f_int8 = 8
    (data, handles) = u.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.ObjectUnion.Deserialize(context)

    self.assertEquals(u, decoded)

  def testObjectInUnionInObjectSerialization(self):
    s = test_unions_mojom.SmallObjStruct()
    s.obj_union = test_unions_mojom.ObjectUnion(
        f_dummy=test_unions_mojom.DummyStruct())
    s.obj_union.f_dummy.f_int8 = 25
    (data, handles) = s.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.SmallObjStruct.Deserialize(context)

    self.assertEquals(s, decoded)

  def testNestedUnionSerialization(self):
    u = test_unions_mojom.ObjectUnion(
        f_pod_union=test_unions_mojom.PodUnion(f_int32=32))

    (data, handles) = u.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.ObjectUnion.Deserialize(context)

    self.assertEquals(u, decoded)

  def testNullableNullObjectInUnionSerialization(self):
    u =  test_unions_mojom.ObjectUnion(f_nullable=None)
    (data, handles) = u.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.ObjectUnion.Deserialize(context)

    self.assertEquals(u, decoded)

  def testNonNullableNullObjectInUnionSerialization(self):
    u =  test_unions_mojom.ObjectUnion(f_dummy=None)
    with self.assertRaises(serialization.SerializationException):
      u.Serialize()

  def testArrayInUnionSerialization(self):
    u = test_unions_mojom.ObjectUnion(
        f_array_int8=[1, 2, 3, 4, 5])
    (data, handles) = u.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.ObjectUnion.Deserialize(context)

    self.assertEquals(u, decoded)

  def testMapInUnionSerialization(self):
    u = test_unions_mojom.ObjectUnion(
        f_map_int8={'one': 1, 'two': 2, 'three': 3})
    (data, handles) = u.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.ObjectUnion.Deserialize(context)

    self.assertEquals(u, decoded)

  def testUnionInObject(self):
    s = test_unions_mojom.SmallStruct()
    s.pod_union = test_unions_mojom.PodUnion(f_uint32=32)
    (data, handles) = s.Serialize()

    # This is where the data should be serialized to.
    size, tag, value = struct.unpack_from('<IIQ', buffer(data), 16)
    self.assertEquals(16, size)
    self.assertEquals(6, tag)
    self.assertEquals(32, value)

    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.SmallStruct.Deserialize(context)

    self.assertEquals(s, decoded)

  def testUnionInArray(self):
    s = test_unions_mojom.SmallStruct()
    s.pod_union_array = [
        test_unions_mojom.PodUnion(f_uint32=32),
        test_unions_mojom.PodUnion(f_uint16=16),
        test_unions_mojom.PodUnion(f_uint64=64),
        ]
    (data, handles) = s.Serialize()

    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.SmallStruct.Deserialize(context)

    self.assertEquals(s, decoded)

  def testNonNullableNullUnionInArray(self):
    s = test_unions_mojom.SmallStruct()
    s.pod_union_array = [
        test_unions_mojom.PodUnion(f_uint32=32),
        None,
        test_unions_mojom.PodUnion(f_uint64=64),
        ]
    with self.assertRaises(serialization.SerializationException):
      s.Serialize()

  def testNullableNullUnionInArray(self):
    s = test_unions_mojom.SmallStruct()
    s.nullable_pod_union_array = [
        test_unions_mojom.PodUnion(f_uint32=32),
        None,
        test_unions_mojom.PodUnion(f_uint64=64),
        ]
    (data, handles) = s.Serialize()

    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.SmallStruct.Deserialize(context)

    self.assertEquals(s, decoded)

  def testUnionInMap(self):
    s = test_unions_mojom.SmallStruct()
    s.pod_union_map = {
        'f_uint32': test_unions_mojom.PodUnion(f_uint32=32),
        'f_uint16': test_unions_mojom.PodUnion(f_uint16=16),
        'f_uint64': test_unions_mojom.PodUnion(f_uint64=64),
        }
    (data, handles) = s.Serialize()

    context = serialization.RootDeserializationContext(data, handles)
    decoded = test_unions_mojom.SmallStruct.Deserialize(context)

    self.assertEquals(s, decoded)
