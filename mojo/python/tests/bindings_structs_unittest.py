# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import math
import unittest

# pylint: disable=E0611,F0401
import mojo_system

# Generated files
# pylint: disable=F0401
import regression_tests_mojom
import sample_import_mojom
import sample_import2_mojom
import sample_service_mojom


class StructBindingsTest(unittest.TestCase):

  def testModule(self):
    self.assertEquals(sample_service_mojom.DefaultsTest.__module__,
                      'sample_service_mojom')

  def testDefaultsTest(self):
    defaults_test = sample_service_mojom.DefaultsTest()
    self.assertEquals(defaults_test.a0, -12)
    self.assertEquals(defaults_test.a1, 12)
    self.assertEquals(defaults_test.a2, 1234)
    self.assertEquals(defaults_test.a3, 34567)
    self.assertEquals(defaults_test.a4, 123456)
    self.assertEquals(defaults_test.a5, 3456789012)
    self.assertEquals(defaults_test.a6, -111111111111)
    self.assertEquals(defaults_test.a7, 9999999999999999999)
    self.assertEquals(defaults_test.a8, 0x12345)
    self.assertEquals(defaults_test.a9, -0x12345)
    self.assertEquals(defaults_test.a10, 1234)
    self.assertEquals(defaults_test.a11, True)
    self.assertEquals(defaults_test.a12, False)
    self.assertEquals(defaults_test.a13, 123.25)
    self.assertEquals(defaults_test.a14, 1234567890.123)
    self.assertEquals(defaults_test.a15, 1E10)
    self.assertEquals(defaults_test.a16, -1.2E+20)
    self.assertEquals(defaults_test.a17, 1.23E-20)
    self.assertEquals(defaults_test.a18, None)
    self.assertEquals(defaults_test.a19, None)
    self.assertEquals(defaults_test.a20, sample_service_mojom.Bar.Type.BOTH)
    self.assertEquals(defaults_test.a21, None)
    self.assertTrue(isinstance(defaults_test.a22, sample_import2_mojom.Thing))
    self.assertEquals(defaults_test.a23, 0xFFFFFFFFFFFFFFFF)
    self.assertEquals(defaults_test.a24, 0x123456789)
    self.assertEquals(defaults_test.a25, -0x123456789)
    self.assertEquals(defaults_test.a26, float('inf'))
    self.assertEquals(defaults_test.a27, float('-inf'))
    self.assertTrue(math.isnan(defaults_test.a28))
    self.assertEquals(defaults_test.a29, float('inf'))
    self.assertEquals(defaults_test.a30, float('-inf'))
    self.assertTrue(math.isnan(defaults_test.a31))

  def testNoAliasing(self):
    foo1 = sample_service_mojom.Foo()
    foo2 = sample_service_mojom.Foo()
    foo1.name = "foo1"
    foo2.name = "foo2"
    self.assertEquals(foo1.name, "foo1")
    self.assertEquals(foo2.name, "foo2")

    defaults_test1 = sample_service_mojom.DefaultsTest()
    defaults_test2 = sample_service_mojom.DefaultsTest()
    self.assertIsNot(defaults_test1.a22, defaults_test2.a22)

  def testImmutableAttributeSet(self):
    foo_instance = sample_service_mojom.Foo()
    with self.assertRaises(AttributeError):
      foo_instance.new_attribute = None
    with self.assertRaises(AttributeError):
      del foo_instance.name

  def _TestIntegerField(self, entity, field_name, bits, signed):
    if signed:
      min_value = -(1 << (bits - 1))
      max_value = (1 << (bits - 1)) - 1
    else:
      min_value = 0
      max_value = (1 << bits) - 1
    entity.__setattr__(field_name, min_value)
    entity.__setattr__(field_name, max_value)
    with self.assertRaises(TypeError):
      entity.__setattr__(field_name, None)
    with self.assertRaises(OverflowError):
      entity.__setattr__(field_name, min_value - 1)
    with self.assertRaises(OverflowError):
      entity.__setattr__(field_name, max_value + 1)
    with self.assertRaises(TypeError):
      entity.__setattr__(field_name, 'hello world')

  def testTypes(self):
    defaults_test = sample_service_mojom.DefaultsTest()
    # Integer types
    self._TestIntegerField(defaults_test, 'a0', 8, True)
    self._TestIntegerField(defaults_test, 'a1', 8, False)
    self._TestIntegerField(defaults_test, 'a2', 16, True)
    self._TestIntegerField(defaults_test, 'a3', 16, False)
    self._TestIntegerField(defaults_test, 'a4', 32, True)
    self._TestIntegerField(defaults_test, 'a5', 32, False)
    self._TestIntegerField(defaults_test, 'a6', 64, True)
    self._TestIntegerField(defaults_test, 'a7', 64, False)

    # Boolean types
    defaults_test.a11 = False
    self.assertEquals(defaults_test.a11, False)
    defaults_test.a11 = None
    self.assertEquals(defaults_test.a11, False)
    defaults_test.a11 = []
    self.assertEquals(defaults_test.a11, False)
    defaults_test.a12 = True
    self.assertEquals(defaults_test.a12, True)
    defaults_test.a12 = 1
    self.assertEquals(defaults_test.a12, True)
    defaults_test.a12 = [[]]
    self.assertEquals(defaults_test.a12, True)

    # Floating point types
    with self.assertRaises(TypeError):
      defaults_test.a13 = 'hello'
    with self.assertRaises(TypeError):
      defaults_test.a14 = 'hello'

    # Array type
    defaults_test.a18 = None
    defaults_test.a18 = []
    defaults_test.a18 = [ 0 ]
    defaults_test.a18 = [ 255 ]
    defaults_test.a18 = [ 0, 255 ]
    with self.assertRaises(TypeError):
      defaults_test.a18 = [[]]
    with self.assertRaises(OverflowError):
      defaults_test.a18 = [ -1 ]
    with self.assertRaises(OverflowError):
      defaults_test.a18 = [ 256 ]

    # String type
    defaults_test.a19 = None
    defaults_test.a19 = ''
    defaults_test.a19 = 'hello world'
    with self.assertRaises(TypeError):
      defaults_test.a19 = [[]]
    with self.assertRaises(TypeError):
      defaults_test.a19 = [ -1 ]
    with self.assertRaises(TypeError):
      defaults_test.a19 = [ 256 ]

    # Structs
    defaults_test.a21 = None
    defaults_test.a21 = sample_import_mojom.Point()
    with self.assertRaises(TypeError):
      defaults_test.a21 = 1
    with self.assertRaises(TypeError):
      defaults_test.a21 = sample_import2_mojom.Thing()

    # Handles
    foo_instance = sample_service_mojom.Foo()
    foo_instance.source = None
    foo_instance.source = mojo_system.Handle()
    with self.assertRaises(TypeError):
      foo_instance.source = 1
    with self.assertRaises(TypeError):
      foo_instance.source = object()

  def testConstructor(self):
    bar_instance = sample_service_mojom.Bar()
    foo_instance = sample_service_mojom.Foo(name="Foo",
                                            x=-1,
                                            y=5,
                                            a=False,
                                            bar=bar_instance)
    self.assertEquals(foo_instance.name, "Foo")
    self.assertEquals(foo_instance.x, -1)
    self.assertEquals(foo_instance.y, 5)
    self.assertEquals(foo_instance.a, False)
    self.assertEquals(foo_instance.bar, bar_instance)

  def testPositionalConstructor(self):
    p = sample_import_mojom.Point()
    self.assertEquals(p.x, 0)
    self.assertEquals(p.y, 0)

    p = sample_import_mojom.Point(34)
    self.assertEquals(p.x, 34)
    self.assertEquals(p.y, 0)

    p = sample_import_mojom.Point(34, 12)
    self.assertEquals(p.x, 34)
    self.assertEquals(p.y, 12)

    p = sample_import_mojom.Point(x=34, y=12)
    self.assertEquals(p.x, 34)
    self.assertEquals(p.y, 12)

    p = sample_import_mojom.Point(34, y=12)
    self.assertEquals(p.x, 34)
    self.assertEquals(p.y, 12)

    with self.assertRaises(TypeError):
      p = sample_import_mojom.Point(0, 0, 0)
    with self.assertRaises(TypeError):
      p = sample_import_mojom.Point(0, x=0)
    with self.assertRaises(TypeError):
      p = sample_import_mojom.Point(c=0)

  def testCyclicDefinition(self):
    a = regression_tests_mojom.A()
    b = regression_tests_mojom.B()
    self.assertIsNone(a.b)
    self.assertIsNone(b.a)
    a.b = b
    self.assertIs(a.b, b)
