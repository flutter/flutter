# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

# Generated files
# pylint: disable=F0401
import sample_import_mojom
import sample_service_mojom


class EnumBindingsTest(unittest.TestCase):

  # Testing enum classes are in the right module.
  def testModule(self):
    self.assertEquals(sample_import_mojom.Shape.__module__,
                      'sample_import_mojom')

  # Testing that enum class have expected constant values.
  def testTopLevelEnumGeneration(self):
    self.assertEquals(sample_import_mojom.Shape.RECTANGLE, 1)
    self.assertEquals(sample_import_mojom.Shape.CIRCLE, 2)
    self.assertEquals(sample_import_mojom.Shape.TRIANGLE, 3)
    self.assertEquals(sample_import_mojom.Shape.LAST,
                      sample_import_mojom.Shape.TRIANGLE)

    self.assertEquals(sample_import_mojom.AnotherShape.RECTANGLE, 10)
    self.assertEquals(sample_import_mojom.AnotherShape.CIRCLE, 11)
    self.assertEquals(sample_import_mojom.AnotherShape.TRIANGLE, 12)

    self.assertEquals(sample_import_mojom.YetAnotherShape.RECTANGLE, 20)
    self.assertEquals(sample_import_mojom.YetAnotherShape.CIRCLE, 21)
    self.assertEquals(sample_import_mojom.YetAnotherShape.TRIANGLE, 22)

  # Testing that internal enum class have expected constant values.
  def testInternalEnumGeneration(self):
    self.assertEquals(sample_service_mojom.Bar.Type.VERTICAL, 1)
    self.assertEquals(sample_service_mojom.Bar.Type.HORIZONTAL, 2)
    self.assertEquals(sample_service_mojom.Bar.Type.BOTH, 3)
    self.assertEquals(sample_service_mojom.Bar.Type.INVALID, 4)

  # Testing an enum class cannot be instantiated.
  def testNonInstantiableEnum(self):
    with self.assertRaises(TypeError):
      sample_import_mojom.Shape()

  # Testing an enum does not contain the VALUES constant.
  def testNoVALUESConstant(self):
    with self.assertRaises(AttributeError):
      # pylint: disable=W0104
      sample_import_mojom.Shape.VALUES

  # Testing enum values are frozen.
  def testEnumFrozen(self):
    with self.assertRaises(AttributeError):
      sample_import_mojom.Shape.RECTANGLE = 2
    with self.assertRaises(AttributeError):
      del sample_import_mojom.Shape.RECTANGLE
    with self.assertRaises(AttributeError):
      sample_import_mojom.Shape.NewShape = 4
