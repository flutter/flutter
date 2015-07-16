# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import math
import unittest

# Generated files
# pylint: disable=F0401
import sample_service_mojom
import test_constants_mojom

class ConstantBindingsTest(unittest.TestCase):

  def testConstantGeneration(self):
    self.assertEquals(test_constants_mojom.INT8_VALUE, -2)
    self.assertEquals(test_constants_mojom.UINT64_VALUE, 9999999999999999999)
    self.assertEquals(test_constants_mojom.DOUBLE_INFINITY,
                      float('inf'))
    self.assertEquals(test_constants_mojom.DOUBLE_NEGATIVE_INFINITY,
                      float('-inf'))
    self.assertTrue(math.isnan(test_constants_mojom.DOUBLE_NA_N))
    self.assertEquals(test_constants_mojom.FLOAT_INFINITY,
                      float('inf'))
    self.assertEquals(test_constants_mojom.FLOAT_NEGATIVE_INFINITY,
                      float('-inf'))
    self.assertTrue(math.isnan(test_constants_mojom.FLOAT_NA_N))

  def testConstantOnStructGeneration(self):
    self.assertEquals(test_constants_mojom.StructWithConstants.INT8_VALUE, 5)

  def testStructImmutability(self):
    with self.assertRaises(AttributeError):
      sample_service_mojom.Foo.FOOBY = 0
    with self.assertRaises(AttributeError):
      del sample_service_mojom.Foo.FOOBY
    with self.assertRaises(AttributeError):
      sample_service_mojom.Foo.BAR = 1
