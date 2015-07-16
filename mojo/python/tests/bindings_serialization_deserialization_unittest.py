# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import math

import mojo_unittest

# pylint: disable=E0611,F0401
import mojo_bindings.serialization as serialization
import mojo_system

# Generated files
# pylint: disable=F0401
import sample_import_mojom
import sample_import2_mojom
import sample_service_mojom


def _NewHandle():
  return mojo_system.MessagePipe().handle0


def _NewBar():
  bar_instance = sample_service_mojom.Bar()
  bar_instance.alpha = 22
  bar_instance.beta = 87
  bar_instance.gamma = 122
  bar_instance.type = sample_service_mojom.Bar.Type.BOTH
  return bar_instance


def _NewFoo():
  foo_instance = sample_service_mojom.Foo()
  foo_instance.name = "Foo.name"
  foo_instance.x = 23
  foo_instance.y = -23
  foo_instance.a = False
  foo_instance.b = True
  foo_instance.c = True
  foo_instance.bar = _NewBar()
  foo_instance.extra_bars = [
      _NewBar(),
      _NewBar(),
  ]
  foo_instance.data = 'Hello world'
  foo_instance.source = _NewHandle()
  foo_instance.input_streams = [ _NewHandle() ]
  foo_instance.output_streams = [ _NewHandle(), _NewHandle() ]
  foo_instance.array_of_array_of_bools = [ [ True, False ], [] ]
  foo_instance.multi_array_of_strings = [
      [
          [ "1", "2" ],
          [],
          [ "3", "4" ],
      ],
      [],
  ]
  foo_instance.array_of_bools = [ True, 0, 1, 2, 0, 0, 0, 0, 0, True ]
  return foo_instance


class SerializationDeserializationTest(mojo_unittest.MojoTestCase):

  def testFooSerialization(self):
    (data, _) = _NewFoo().Serialize()
    self.assertTrue(len(data))
    self.assertEquals(len(data) % 8, 0)

  def testFooDeserialization(self):
    (data, handles) = _NewFoo().Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    self.assertTrue(
        sample_service_mojom.Foo.Deserialize(context))

  def testFooSerializationDeserialization(self):
    foo1 = _NewFoo()
    (data, handles) = foo1.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    foo2 = sample_service_mojom.Foo.Deserialize(context)
    self.assertEquals(foo1, foo2)

  def testDefaultsTestSerializationDeserialization(self):
    v1 = sample_service_mojom.DefaultsTest()
    v1.a18 = []
    v1.a19 = ""
    v1.a21 = sample_import_mojom.Point()
    v1.a22.location = sample_import_mojom.Point()
    v1.a22.size = sample_import2_mojom.Size()
    (data, handles) = v1.Serialize()
    context = serialization.RootDeserializationContext(data, handles)
    v2 = sample_service_mojom.DefaultsTest.Deserialize(context)
    # NaN needs to be a special case.
    self.assertNotEquals(v1, v2)
    self.assertTrue(math.isnan(v2.a28))
    self.assertTrue(math.isnan(v2.a31))
    v1.a28 = v2.a28 = v1.a31 = v2.a31 = 0
    self.assertEquals(v1, v2)

  def testFooDeserializationError(self):
    with self.assertRaises(Exception):
      sample_service_mojom.Foo.Deserialize("", [])
