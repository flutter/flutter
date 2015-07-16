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

# TODO(robinson): Flesh this out considerably.  We focused on reflection_test.py
# first, since it's testing the subtler code, and since it provides decent
# indirect testing of the protocol compiler output.

"""Unittest that directly tests the output of the pure-Python protocol
compiler.  See //google/protobuf/reflection_test.py for a test which
further ensures that we can use Python protocol message objects as we expect.
"""

__author__ = 'robinson@google.com (Will Robinson)'

import unittest
from google.protobuf.internal import test_bad_identifiers_pb2
from google.protobuf import unittest_custom_options_pb2
from google.protobuf import unittest_import_pb2
from google.protobuf import unittest_import_public_pb2
from google.protobuf import unittest_mset_pb2
from google.protobuf import unittest_pb2
from google.protobuf import unittest_no_generic_services_pb2
from google.protobuf import service

MAX_EXTENSION = 536870912


class GeneratorTest(unittest.TestCase):

  def testNestedMessageDescriptor(self):
    field_name = 'optional_nested_message'
    proto_type = unittest_pb2.TestAllTypes
    self.assertEqual(
        proto_type.NestedMessage.DESCRIPTOR,
        proto_type.DESCRIPTOR.fields_by_name[field_name].message_type)

  def testEnums(self):
    # We test only module-level enums here.
    # TODO(robinson): Examine descriptors directly to check
    # enum descriptor output.
    self.assertEqual(4, unittest_pb2.FOREIGN_FOO)
    self.assertEqual(5, unittest_pb2.FOREIGN_BAR)
    self.assertEqual(6, unittest_pb2.FOREIGN_BAZ)

    proto = unittest_pb2.TestAllTypes()
    self.assertEqual(1, proto.FOO)
    self.assertEqual(1, unittest_pb2.TestAllTypes.FOO)
    self.assertEqual(2, proto.BAR)
    self.assertEqual(2, unittest_pb2.TestAllTypes.BAR)
    self.assertEqual(3, proto.BAZ)
    self.assertEqual(3, unittest_pb2.TestAllTypes.BAZ)

  def testExtremeDefaultValues(self):
    message = unittest_pb2.TestExtremeDefaultValues()

    # Python pre-2.6 does not have isinf() or isnan() functions, so we have
    # to provide our own.
    def isnan(val):
      # NaN is never equal to itself.
      return val != val
    def isinf(val):
      # Infinity times zero equals NaN.
      return not isnan(val) and isnan(val * 0)

    self.assertTrue(isinf(message.inf_double))
    self.assertTrue(message.inf_double > 0)
    self.assertTrue(isinf(message.neg_inf_double))
    self.assertTrue(message.neg_inf_double < 0)
    self.assertTrue(isnan(message.nan_double))

    self.assertTrue(isinf(message.inf_float))
    self.assertTrue(message.inf_float > 0)
    self.assertTrue(isinf(message.neg_inf_float))
    self.assertTrue(message.neg_inf_float < 0)
    self.assertTrue(isnan(message.nan_float))
    self.assertEqual("? ? ?? ?? ??? ??/ ??-", message.cpp_trigraph)

  def testHasDefaultValues(self):
    desc = unittest_pb2.TestAllTypes.DESCRIPTOR

    expected_has_default_by_name = {
        'optional_int32': False,
        'repeated_int32': False,
        'optional_nested_message': False,
        'default_int32': True,
    }

    has_default_by_name = dict(
        [(f.name, f.has_default_value)
         for f in desc.fields
         if f.name in expected_has_default_by_name])
    self.assertEqual(expected_has_default_by_name, has_default_by_name)

  def testContainingTypeBehaviorForExtensions(self):
    self.assertEqual(unittest_pb2.optional_int32_extension.containing_type,
                     unittest_pb2.TestAllExtensions.DESCRIPTOR)
    self.assertEqual(unittest_pb2.TestRequired.single.containing_type,
                     unittest_pb2.TestAllExtensions.DESCRIPTOR)

  def testExtensionScope(self):
    self.assertEqual(unittest_pb2.optional_int32_extension.extension_scope,
                     None)
    self.assertEqual(unittest_pb2.TestRequired.single.extension_scope,
                     unittest_pb2.TestRequired.DESCRIPTOR)

  def testIsExtension(self):
    self.assertTrue(unittest_pb2.optional_int32_extension.is_extension)
    self.assertTrue(unittest_pb2.TestRequired.single.is_extension)

    message_descriptor = unittest_pb2.TestRequired.DESCRIPTOR
    non_extension_descriptor = message_descriptor.fields_by_name['a']
    self.assertTrue(not non_extension_descriptor.is_extension)

  def testOptions(self):
    proto = unittest_mset_pb2.TestMessageSet()
    self.assertTrue(proto.DESCRIPTOR.GetOptions().message_set_wire_format)

  def testMessageWithCustomOptions(self):
    proto = unittest_custom_options_pb2.TestMessageWithCustomOptions()
    enum_options = proto.DESCRIPTOR.enum_types_by_name['AnEnum'].GetOptions()
    self.assertTrue(enum_options is not None)
    # TODO(gps): We really should test for the presense of the enum_opt1
    # extension and for its value to be set to -789.

  def testNestedTypes(self):
    self.assertEquals(
        set(unittest_pb2.TestAllTypes.DESCRIPTOR.nested_types),
        set([
            unittest_pb2.TestAllTypes.NestedMessage.DESCRIPTOR,
            unittest_pb2.TestAllTypes.OptionalGroup.DESCRIPTOR,
            unittest_pb2.TestAllTypes.RepeatedGroup.DESCRIPTOR,
        ]))
    self.assertEqual(unittest_pb2.TestEmptyMessage.DESCRIPTOR.nested_types, [])
    self.assertEqual(
        unittest_pb2.TestAllTypes.NestedMessage.DESCRIPTOR.nested_types, [])

  def testContainingType(self):
    self.assertTrue(
        unittest_pb2.TestEmptyMessage.DESCRIPTOR.containing_type is None)
    self.assertTrue(
        unittest_pb2.TestAllTypes.DESCRIPTOR.containing_type is None)
    self.assertEqual(
        unittest_pb2.TestAllTypes.NestedMessage.DESCRIPTOR.containing_type,
        unittest_pb2.TestAllTypes.DESCRIPTOR)
    self.assertEqual(
        unittest_pb2.TestAllTypes.NestedMessage.DESCRIPTOR.containing_type,
        unittest_pb2.TestAllTypes.DESCRIPTOR)
    self.assertEqual(
        unittest_pb2.TestAllTypes.RepeatedGroup.DESCRIPTOR.containing_type,
        unittest_pb2.TestAllTypes.DESCRIPTOR)

  def testContainingTypeInEnumDescriptor(self):
    self.assertTrue(unittest_pb2._FOREIGNENUM.containing_type is None)
    self.assertEqual(unittest_pb2._TESTALLTYPES_NESTEDENUM.containing_type,
                     unittest_pb2.TestAllTypes.DESCRIPTOR)

  def testPackage(self):
    self.assertEqual(
        unittest_pb2.TestAllTypes.DESCRIPTOR.file.package,
        'protobuf_unittest')
    desc = unittest_pb2.TestAllTypes.NestedMessage.DESCRIPTOR
    self.assertEqual(desc.file.package, 'protobuf_unittest')
    self.assertEqual(
        unittest_import_pb2.ImportMessage.DESCRIPTOR.file.package,
        'protobuf_unittest_import')

    self.assertEqual(
        unittest_pb2._FOREIGNENUM.file.package, 'protobuf_unittest')
    self.assertEqual(
        unittest_pb2._TESTALLTYPES_NESTEDENUM.file.package,
        'protobuf_unittest')
    self.assertEqual(
        unittest_import_pb2._IMPORTENUM.file.package,
        'protobuf_unittest_import')

  def testExtensionRange(self):
    self.assertEqual(
        unittest_pb2.TestAllTypes.DESCRIPTOR.extension_ranges, [])
    self.assertEqual(
        unittest_pb2.TestAllExtensions.DESCRIPTOR.extension_ranges,
        [(1, MAX_EXTENSION)])
    self.assertEqual(
        unittest_pb2.TestMultipleExtensionRanges.DESCRIPTOR.extension_ranges,
        [(42, 43), (4143, 4244), (65536, MAX_EXTENSION)])

  def testFileDescriptor(self):
    self.assertEqual(unittest_pb2.DESCRIPTOR.name,
                     'google/protobuf/unittest.proto')
    self.assertEqual(unittest_pb2.DESCRIPTOR.package, 'protobuf_unittest')
    self.assertFalse(unittest_pb2.DESCRIPTOR.serialized_pb is None)

  def testNoGenericServices(self):
    self.assertTrue(hasattr(unittest_no_generic_services_pb2, "TestMessage"))
    self.assertTrue(hasattr(unittest_no_generic_services_pb2, "FOO"))
    self.assertTrue(hasattr(unittest_no_generic_services_pb2, "test_extension"))

    # Make sure unittest_no_generic_services_pb2 has no services subclassing
    # Proto2 Service class.
    if hasattr(unittest_no_generic_services_pb2, "TestService"):
      self.assertFalse(issubclass(unittest_no_generic_services_pb2.TestService,
                                  service.Service))

  def testMessageTypesByName(self):
    file_type = unittest_pb2.DESCRIPTOR
    self.assertEqual(
        unittest_pb2._TESTALLTYPES,
        file_type.message_types_by_name[unittest_pb2._TESTALLTYPES.name])

    # Nested messages shouldn't be included in the message_types_by_name
    # dictionary (like in the C++ API).
    self.assertFalse(
        unittest_pb2._TESTALLTYPES_NESTEDMESSAGE.name in
        file_type.message_types_by_name)

  def testPublicImports(self):
    # Test public imports as embedded message.
    all_type_proto = unittest_pb2.TestAllTypes()
    self.assertEqual(0, all_type_proto.optional_public_import_message.e)

    # PublicImportMessage is actually defined in unittest_import_public_pb2
    # module, and is public imported by unittest_import_pb2 module.
    public_import_proto = unittest_import_pb2.PublicImportMessage()
    self.assertEqual(0, public_import_proto.e)
    self.assertTrue(unittest_import_public_pb2.PublicImportMessage is
                    unittest_import_pb2.PublicImportMessage)

  def testBadIdentifiers(self):
    # We're just testing that the code was imported without problems.
    message = test_bad_identifiers_pb2.TestBadIdentifiers()
    self.assertEqual(message.Extensions[test_bad_identifiers_pb2.message],
                     "foo")
    self.assertEqual(message.Extensions[test_bad_identifiers_pb2.descriptor],
                     "bar")
    self.assertEqual(message.Extensions[test_bad_identifiers_pb2.reflection],
                     "baz")
    self.assertEqual(message.Extensions[test_bad_identifiers_pb2.service],
                     "qux")

if __name__ == '__main__':
  unittest.main()
