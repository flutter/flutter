# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import mojo_unittest
from mojo_bindings import reflection
from mojo_bindings import interface_reflection


class GenerationTest(mojo_unittest.MojoTestCase):

  TEST_PACKAGES = [
    'math_calculator_mojom',
    'no_module_mojom',
    'rect_mojom',
    'regression_tests_mojom',
    'sample_factory_mojom',
    'sample_import2_mojom',
    'sample_import_mojom',
    'sample_interfaces_mojom',
    'sample_service_mojom',
    'serialization_test_structs_mojom',
    'test_structs_mojom',
    'validation_test_interfaces_mojom',
  ]

  @staticmethod
  def testGeneration():
    buildable_types = (reflection.MojoStructType,
                       interface_reflection.MojoInterfaceType)
    for module_name in GenerationTest.TEST_PACKAGES:
      module = __import__(module_name)
      for element_name in dir(module):
        element = getattr(module, element_name)
        if isinstance(element, buildable_types):
          # Check struct and interface are buildable
          element()
