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

"""Unittest for google.protobuf.internal.descriptor."""

__author__ = 'robinson@google.com (Will Robinson)'

import unittest
from google.protobuf import unittest_custom_options_pb2
from google.protobuf import unittest_import_pb2
from google.protobuf import unittest_pb2
from google.protobuf import descriptor_pb2
from google.protobuf import descriptor
from google.protobuf import text_format


TEST_EMPTY_MESSAGE_DESCRIPTOR_ASCII = """
name: 'TestEmptyMessage'
"""


class DescriptorTest(unittest.TestCase):

  def setUp(self):
    self.my_file = descriptor.FileDescriptor(
        name='some/filename/some.proto',
        package='protobuf_unittest'
        )
    self.my_enum = descriptor.EnumDescriptor(
        name='ForeignEnum',
        full_name='protobuf_unittest.ForeignEnum',
        filename=None,
        file=self.my_file,
        values=[
          descriptor.EnumValueDescriptor(name='FOREIGN_FOO', index=0, number=4),
          descriptor.EnumValueDescriptor(name='FOREIGN_BAR', index=1, number=5),
          descriptor.EnumValueDescriptor(name='FOREIGN_BAZ', index=2, number=6),
        ])
    self.my_message = descriptor.Descriptor(
        name='NestedMessage',
        full_name='protobuf_unittest.TestAllTypes.NestedMessage',
        filename=None,
        file=self.my_file,
        containing_type=None,
        fields=[
          descriptor.FieldDescriptor(
            name='bb',
            full_name='protobuf_unittest.TestAllTypes.NestedMessage.bb',
            index=0, number=1,
            type=5, cpp_type=1, label=1,
            has_default_value=False, default_value=0,
            message_type=None, enum_type=None, containing_type=None,
            is_extension=False, extension_scope=None),
        ],
        nested_types=[],
        enum_types=[
          self.my_enum,
        ],
        extensions=[])
    self.my_method = descriptor.MethodDescriptor(
        name='Bar',
        full_name='protobuf_unittest.TestService.Bar',
        index=0,
        containing_service=None,
        input_type=None,
        output_type=None)
    self.my_service = descriptor.ServiceDescriptor(
        name='TestServiceWithOptions',
        full_name='protobuf_unittest.TestServiceWithOptions',
        file=self.my_file,
        index=0,
        methods=[
            self.my_method
        ])

  def testEnumValueName(self):
    self.assertEqual(self.my_message.EnumValueName('ForeignEnum', 4),
                     'FOREIGN_FOO')

    self.assertEqual(
        self.my_message.enum_types_by_name[
            'ForeignEnum'].values_by_number[4].name,
        self.my_message.EnumValueName('ForeignEnum', 4))

  def testEnumFixups(self):
    self.assertEqual(self.my_enum, self.my_enum.values[0].type)

  def testContainingTypeFixups(self):
    self.assertEqual(self.my_message, self.my_message.fields[0].containing_type)
    self.assertEqual(self.my_message, self.my_enum.containing_type)

  def testContainingServiceFixups(self):
    self.assertEqual(self.my_service, self.my_method.containing_service)

  def testGetOptions(self):
    self.assertEqual(self.my_enum.GetOptions(),
                     descriptor_pb2.EnumOptions())
    self.assertEqual(self.my_enum.values[0].GetOptions(),
                     descriptor_pb2.EnumValueOptions())
    self.assertEqual(self.my_message.GetOptions(),
                     descriptor_pb2.MessageOptions())
    self.assertEqual(self.my_message.fields[0].GetOptions(),
                     descriptor_pb2.FieldOptions())
    self.assertEqual(self.my_method.GetOptions(),
                     descriptor_pb2.MethodOptions())
    self.assertEqual(self.my_service.GetOptions(),
                     descriptor_pb2.ServiceOptions())

  def testSimpleCustomOptions(self):
    file_descriptor = unittest_custom_options_pb2.DESCRIPTOR
    message_descriptor =\
        unittest_custom_options_pb2.TestMessageWithCustomOptions.DESCRIPTOR
    field_descriptor = message_descriptor.fields_by_name["field1"]
    enum_descriptor = message_descriptor.enum_types_by_name["AnEnum"]
    enum_value_descriptor =\
        message_descriptor.enum_values_by_name["ANENUM_VAL2"]
    service_descriptor =\
        unittest_custom_options_pb2.TestServiceWithCustomOptions.DESCRIPTOR
    method_descriptor = service_descriptor.FindMethodByName("Foo")

    file_options = file_descriptor.GetOptions()
    file_opt1 = unittest_custom_options_pb2.file_opt1
    self.assertEqual(9876543210, file_options.Extensions[file_opt1])
    message_options = message_descriptor.GetOptions()
    message_opt1 = unittest_custom_options_pb2.message_opt1
    self.assertEqual(-56, message_options.Extensions[message_opt1])
    field_options = field_descriptor.GetOptions()
    field_opt1 = unittest_custom_options_pb2.field_opt1
    self.assertEqual(8765432109, field_options.Extensions[field_opt1])
    field_opt2 = unittest_custom_options_pb2.field_opt2
    self.assertEqual(42, field_options.Extensions[field_opt2])
    enum_options = enum_descriptor.GetOptions()
    enum_opt1 = unittest_custom_options_pb2.enum_opt1
    self.assertEqual(-789, enum_options.Extensions[enum_opt1])
    enum_value_options = enum_value_descriptor.GetOptions()
    enum_value_opt1 = unittest_custom_options_pb2.enum_value_opt1
    self.assertEqual(123, enum_value_options.Extensions[enum_value_opt1])

    service_options = service_descriptor.GetOptions()
    service_opt1 = unittest_custom_options_pb2.service_opt1
    self.assertEqual(-9876543210, service_options.Extensions[service_opt1])
    method_options = method_descriptor.GetOptions()
    method_opt1 = unittest_custom_options_pb2.method_opt1
    self.assertEqual(unittest_custom_options_pb2.METHODOPT1_VAL2,
                     method_options.Extensions[method_opt1])

  def testDifferentCustomOptionTypes(self):
    kint32min = -2**31
    kint64min = -2**63
    kint32max = 2**31 - 1
    kint64max = 2**63 - 1
    kuint32max = 2**32 - 1
    kuint64max = 2**64 - 1

    message_descriptor =\
        unittest_custom_options_pb2.CustomOptionMinIntegerValues.DESCRIPTOR
    message_options = message_descriptor.GetOptions()
    self.assertEqual(False, message_options.Extensions[
        unittest_custom_options_pb2.bool_opt])
    self.assertEqual(kint32min, message_options.Extensions[
        unittest_custom_options_pb2.int32_opt])
    self.assertEqual(kint64min, message_options.Extensions[
        unittest_custom_options_pb2.int64_opt])
    self.assertEqual(0, message_options.Extensions[
        unittest_custom_options_pb2.uint32_opt])
    self.assertEqual(0, message_options.Extensions[
        unittest_custom_options_pb2.uint64_opt])
    self.assertEqual(kint32min, message_options.Extensions[
        unittest_custom_options_pb2.sint32_opt])
    self.assertEqual(kint64min, message_options.Extensions[
        unittest_custom_options_pb2.sint64_opt])
    self.assertEqual(0, message_options.Extensions[
        unittest_custom_options_pb2.fixed32_opt])
    self.assertEqual(0, message_options.Extensions[
        unittest_custom_options_pb2.fixed64_opt])
    self.assertEqual(kint32min, message_options.Extensions[
        unittest_custom_options_pb2.sfixed32_opt])
    self.assertEqual(kint64min, message_options.Extensions[
        unittest_custom_options_pb2.sfixed64_opt])

    message_descriptor =\
        unittest_custom_options_pb2.CustomOptionMaxIntegerValues.DESCRIPTOR
    message_options = message_descriptor.GetOptions()
    self.assertEqual(True, message_options.Extensions[
        unittest_custom_options_pb2.bool_opt])
    self.assertEqual(kint32max, message_options.Extensions[
        unittest_custom_options_pb2.int32_opt])
    self.assertEqual(kint64max, message_options.Extensions[
        unittest_custom_options_pb2.int64_opt])
    self.assertEqual(kuint32max, message_options.Extensions[
        unittest_custom_options_pb2.uint32_opt])
    self.assertEqual(kuint64max, message_options.Extensions[
        unittest_custom_options_pb2.uint64_opt])
    self.assertEqual(kint32max, message_options.Extensions[
        unittest_custom_options_pb2.sint32_opt])
    self.assertEqual(kint64max, message_options.Extensions[
        unittest_custom_options_pb2.sint64_opt])
    self.assertEqual(kuint32max, message_options.Extensions[
        unittest_custom_options_pb2.fixed32_opt])
    self.assertEqual(kuint64max, message_options.Extensions[
        unittest_custom_options_pb2.fixed64_opt])
    self.assertEqual(kint32max, message_options.Extensions[
        unittest_custom_options_pb2.sfixed32_opt])
    self.assertEqual(kint64max, message_options.Extensions[
        unittest_custom_options_pb2.sfixed64_opt])

    message_descriptor =\
        unittest_custom_options_pb2.CustomOptionOtherValues.DESCRIPTOR
    message_options = message_descriptor.GetOptions()
    self.assertEqual(-100, message_options.Extensions[
        unittest_custom_options_pb2.int32_opt])
    self.assertAlmostEqual(12.3456789, message_options.Extensions[
        unittest_custom_options_pb2.float_opt], 6)
    self.assertAlmostEqual(1.234567890123456789, message_options.Extensions[
        unittest_custom_options_pb2.double_opt])
    self.assertEqual("Hello, \"World\"", message_options.Extensions[
        unittest_custom_options_pb2.string_opt])
    self.assertEqual("Hello\0World", message_options.Extensions[
        unittest_custom_options_pb2.bytes_opt])
    dummy_enum = unittest_custom_options_pb2.DummyMessageContainingEnum
    self.assertEqual(
        dummy_enum.TEST_OPTION_ENUM_TYPE2,
        message_options.Extensions[unittest_custom_options_pb2.enum_opt])

    message_descriptor =\
        unittest_custom_options_pb2.SettingRealsFromPositiveInts.DESCRIPTOR
    message_options = message_descriptor.GetOptions()
    self.assertAlmostEqual(12, message_options.Extensions[
        unittest_custom_options_pb2.float_opt], 6)
    self.assertAlmostEqual(154, message_options.Extensions[
        unittest_custom_options_pb2.double_opt])

    message_descriptor =\
        unittest_custom_options_pb2.SettingRealsFromNegativeInts.DESCRIPTOR
    message_options = message_descriptor.GetOptions()
    self.assertAlmostEqual(-12, message_options.Extensions[
        unittest_custom_options_pb2.float_opt], 6)
    self.assertAlmostEqual(-154, message_options.Extensions[
        unittest_custom_options_pb2.double_opt])

  def testComplexExtensionOptions(self):
    descriptor =\
        unittest_custom_options_pb2.VariousComplexOptions.DESCRIPTOR
    options = descriptor.GetOptions()
    self.assertEqual(42, options.Extensions[
        unittest_custom_options_pb2.complex_opt1].foo)
    self.assertEqual(324, options.Extensions[
        unittest_custom_options_pb2.complex_opt1].Extensions[
            unittest_custom_options_pb2.quux])
    self.assertEqual(876, options.Extensions[
        unittest_custom_options_pb2.complex_opt1].Extensions[
            unittest_custom_options_pb2.corge].qux)
    self.assertEqual(987, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].baz)
    self.assertEqual(654, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].Extensions[
            unittest_custom_options_pb2.grault])
    self.assertEqual(743, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].bar.foo)
    self.assertEqual(1999, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].bar.Extensions[
            unittest_custom_options_pb2.quux])
    self.assertEqual(2008, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].bar.Extensions[
            unittest_custom_options_pb2.corge].qux)
    self.assertEqual(741, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].Extensions[
            unittest_custom_options_pb2.garply].foo)
    self.assertEqual(1998, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].Extensions[
            unittest_custom_options_pb2.garply].Extensions[
                unittest_custom_options_pb2.quux])
    self.assertEqual(2121, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].Extensions[
            unittest_custom_options_pb2.garply].Extensions[
                unittest_custom_options_pb2.corge].qux)
    self.assertEqual(1971, options.Extensions[
        unittest_custom_options_pb2.ComplexOptionType2
        .ComplexOptionType4.complex_opt4].waldo)
    self.assertEqual(321, options.Extensions[
        unittest_custom_options_pb2.complex_opt2].fred.waldo)
    self.assertEqual(9, options.Extensions[
        unittest_custom_options_pb2.complex_opt3].qux)
    self.assertEqual(22, options.Extensions[
        unittest_custom_options_pb2.complex_opt3].complexoptiontype5.plugh)
    self.assertEqual(24, options.Extensions[
        unittest_custom_options_pb2.complexopt6].xyzzy)

  # Check that aggregate options were parsed and saved correctly in
  # the appropriate descriptors.
  def testAggregateOptions(self):
    file_descriptor = unittest_custom_options_pb2.DESCRIPTOR
    message_descriptor =\
        unittest_custom_options_pb2.AggregateMessage.DESCRIPTOR
    field_descriptor = message_descriptor.fields_by_name["fieldname"]
    enum_descriptor = unittest_custom_options_pb2.AggregateEnum.DESCRIPTOR
    enum_value_descriptor = enum_descriptor.values_by_name["VALUE"]
    service_descriptor =\
        unittest_custom_options_pb2.AggregateService.DESCRIPTOR
    method_descriptor = service_descriptor.FindMethodByName("Method")

    # Tests for the different types of data embedded in fileopt
    file_options = file_descriptor.GetOptions().Extensions[
        unittest_custom_options_pb2.fileopt]
    self.assertEqual(100, file_options.i)
    self.assertEqual("FileAnnotation", file_options.s)
    self.assertEqual("NestedFileAnnotation", file_options.sub.s)
    self.assertEqual("FileExtensionAnnotation", file_options.file.Extensions[
        unittest_custom_options_pb2.fileopt].s)
    self.assertEqual("EmbeddedMessageSetElement", file_options.mset.Extensions[
        unittest_custom_options_pb2.AggregateMessageSetElement
        .message_set_extension].s)

    # Simple tests for all the other types of annotations
    self.assertEqual(
        "MessageAnnotation",
        message_descriptor.GetOptions().Extensions[
            unittest_custom_options_pb2.msgopt].s)
    self.assertEqual(
        "FieldAnnotation",
        field_descriptor.GetOptions().Extensions[
            unittest_custom_options_pb2.fieldopt].s)
    self.assertEqual(
        "EnumAnnotation",
        enum_descriptor.GetOptions().Extensions[
            unittest_custom_options_pb2.enumopt].s)
    self.assertEqual(
        "EnumValueAnnotation",
        enum_value_descriptor.GetOptions().Extensions[
            unittest_custom_options_pb2.enumvalopt].s)
    self.assertEqual(
        "ServiceAnnotation",
        service_descriptor.GetOptions().Extensions[
            unittest_custom_options_pb2.serviceopt].s)
    self.assertEqual(
        "MethodAnnotation",
        method_descriptor.GetOptions().Extensions[
            unittest_custom_options_pb2.methodopt].s)

  def testNestedOptions(self):
    nested_message =\
        unittest_custom_options_pb2.NestedOptionType.NestedMessage.DESCRIPTOR
    self.assertEqual(1001, nested_message.GetOptions().Extensions[
        unittest_custom_options_pb2.message_opt1])
    nested_field = nested_message.fields_by_name["nested_field"]
    self.assertEqual(1002, nested_field.GetOptions().Extensions[
        unittest_custom_options_pb2.field_opt1])
    outer_message =\
        unittest_custom_options_pb2.NestedOptionType.DESCRIPTOR
    nested_enum = outer_message.enum_types_by_name["NestedEnum"]
    self.assertEqual(1003, nested_enum.GetOptions().Extensions[
        unittest_custom_options_pb2.enum_opt1])
    nested_enum_value = outer_message.enum_values_by_name["NESTED_ENUM_VALUE"]
    self.assertEqual(1004, nested_enum_value.GetOptions().Extensions[
        unittest_custom_options_pb2.enum_value_opt1])
    nested_extension = outer_message.extensions_by_name["nested_extension"]
    self.assertEqual(1005, nested_extension.GetOptions().Extensions[
        unittest_custom_options_pb2.field_opt2])

  def testFileDescriptorReferences(self):
    self.assertEqual(self.my_enum.file, self.my_file)
    self.assertEqual(self.my_message.file, self.my_file)

  def testFileDescriptor(self):
    self.assertEqual(self.my_file.name, 'some/filename/some.proto')
    self.assertEqual(self.my_file.package, 'protobuf_unittest')


class DescriptorCopyToProtoTest(unittest.TestCase):
  """Tests for CopyTo functions of Descriptor."""

  def _AssertProtoEqual(self, actual_proto, expected_class, expected_ascii):
    expected_proto = expected_class()
    text_format.Merge(expected_ascii, expected_proto)

    self.assertEqual(
        actual_proto, expected_proto,
        'Not equal,\nActual:\n%s\nExpected:\n%s\n'
        % (str(actual_proto), str(expected_proto)))

  def _InternalTestCopyToProto(self, desc, expected_proto_class,
                               expected_proto_ascii):
    actual = expected_proto_class()
    desc.CopyToProto(actual)
    self._AssertProtoEqual(
        actual, expected_proto_class, expected_proto_ascii)

  def testCopyToProto_EmptyMessage(self):
    self._InternalTestCopyToProto(
        unittest_pb2.TestEmptyMessage.DESCRIPTOR,
        descriptor_pb2.DescriptorProto,
        TEST_EMPTY_MESSAGE_DESCRIPTOR_ASCII)

  def testCopyToProto_NestedMessage(self):
    TEST_NESTED_MESSAGE_ASCII = """
      name: 'NestedMessage'
      field: <
        name: 'bb'
        number: 1
        label: 1  # Optional
        type: 5  # TYPE_INT32
      >
      """

    self._InternalTestCopyToProto(
        unittest_pb2.TestAllTypes.NestedMessage.DESCRIPTOR,
        descriptor_pb2.DescriptorProto,
        TEST_NESTED_MESSAGE_ASCII)

  def testCopyToProto_ForeignNestedMessage(self):
    TEST_FOREIGN_NESTED_ASCII = """
      name: 'TestForeignNested'
      field: <
        name: 'foreign_nested'
        number: 1
        label: 1  # Optional
        type: 11  # TYPE_MESSAGE
        type_name: '.protobuf_unittest.TestAllTypes.NestedMessage'
      >
      """

    self._InternalTestCopyToProto(
        unittest_pb2.TestForeignNested.DESCRIPTOR,
        descriptor_pb2.DescriptorProto,
        TEST_FOREIGN_NESTED_ASCII)

  def testCopyToProto_ForeignEnum(self):
    TEST_FOREIGN_ENUM_ASCII = """
      name: 'ForeignEnum'
      value: <
        name: 'FOREIGN_FOO'
        number: 4
      >
      value: <
        name: 'FOREIGN_BAR'
        number: 5
      >
      value: <
        name: 'FOREIGN_BAZ'
        number: 6
      >
      """

    self._InternalTestCopyToProto(
        unittest_pb2._FOREIGNENUM,
        descriptor_pb2.EnumDescriptorProto,
        TEST_FOREIGN_ENUM_ASCII)

  def testCopyToProto_Options(self):
    TEST_DEPRECATED_FIELDS_ASCII = """
      name: 'TestDeprecatedFields'
      field: <
        name: 'deprecated_int32'
        number: 1
        label: 1  # Optional
        type: 5  # TYPE_INT32
        options: <
          deprecated: true
        >
      >
      """

    self._InternalTestCopyToProto(
        unittest_pb2.TestDeprecatedFields.DESCRIPTOR,
        descriptor_pb2.DescriptorProto,
        TEST_DEPRECATED_FIELDS_ASCII)

  def testCopyToProto_AllExtensions(self):
    TEST_EMPTY_MESSAGE_WITH_EXTENSIONS_ASCII = """
      name: 'TestEmptyMessageWithExtensions'
      extension_range: <
        start: 1
        end: 536870912
      >
      """

    self._InternalTestCopyToProto(
        unittest_pb2.TestEmptyMessageWithExtensions.DESCRIPTOR,
        descriptor_pb2.DescriptorProto,
        TEST_EMPTY_MESSAGE_WITH_EXTENSIONS_ASCII)

  def testCopyToProto_SeveralExtensions(self):
    TEST_MESSAGE_WITH_SEVERAL_EXTENSIONS_ASCII = """
      name: 'TestMultipleExtensionRanges'
      extension_range: <
        start: 42
        end: 43
      >
      extension_range: <
        start: 4143
        end: 4244
      >
      extension_range: <
        start: 65536
        end: 536870912
      >
      """

    self._InternalTestCopyToProto(
        unittest_pb2.TestMultipleExtensionRanges.DESCRIPTOR,
        descriptor_pb2.DescriptorProto,
        TEST_MESSAGE_WITH_SEVERAL_EXTENSIONS_ASCII)

  def testCopyToProto_FileDescriptor(self):
    UNITTEST_IMPORT_FILE_DESCRIPTOR_ASCII = ("""
      name: 'google/protobuf/unittest_import.proto'
      package: 'protobuf_unittest_import'
      dependency: 'google/protobuf/unittest_import_public.proto'
      message_type: <
        name: 'ImportMessage'
        field: <
          name: 'd'
          number: 1
          label: 1  # Optional
          type: 5  # TYPE_INT32
        >
      >
      """ +
      """enum_type: <
        name: 'ImportEnum'
        value: <
          name: 'IMPORT_FOO'
          number: 7
        >
        value: <
          name: 'IMPORT_BAR'
          number: 8
        >
        value: <
          name: 'IMPORT_BAZ'
          number: 9
        >
      >
      options: <
        java_package: 'com.google.protobuf.test'
        optimize_for: 1  # SPEED
      >
      public_dependency: 0
      """)

    self._InternalTestCopyToProto(
        unittest_import_pb2.DESCRIPTOR,
        descriptor_pb2.FileDescriptorProto,
        UNITTEST_IMPORT_FILE_DESCRIPTOR_ASCII)

  def testCopyToProto_ServiceDescriptor(self):
    TEST_SERVICE_ASCII = """
      name: 'TestService'
      method: <
        name: 'Foo'
        input_type: '.protobuf_unittest.FooRequest'
        output_type: '.protobuf_unittest.FooResponse'
      >
      method: <
        name: 'Bar'
        input_type: '.protobuf_unittest.BarRequest'
        output_type: '.protobuf_unittest.BarResponse'
      >
      """

    self._InternalTestCopyToProto(
        unittest_pb2.TestService.DESCRIPTOR,
        descriptor_pb2.ServiceDescriptorProto,
        TEST_SERVICE_ASCII)


class MakeDescriptorTest(unittest.TestCase):
  def testMakeDescriptorWithUnsignedIntField(self):
    file_descriptor_proto = descriptor_pb2.FileDescriptorProto()
    file_descriptor_proto.name = 'Foo'
    message_type = file_descriptor_proto.message_type.add()
    message_type.name = file_descriptor_proto.name
    field = message_type.field.add()
    field.number = 1
    field.name = 'uint64_field'
    field.label = descriptor.FieldDescriptor.LABEL_REQUIRED
    field.type = descriptor.FieldDescriptor.TYPE_UINT64
    result = descriptor.MakeDescriptor(message_type)
    self.assertEqual(result.fields[0].cpp_type,
                     descriptor.FieldDescriptor.CPPTYPE_UINT64)


if __name__ == '__main__':
  unittest.main()
