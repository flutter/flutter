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

"""Test for google.protobuf.text_format."""

__author__ = 'kenton@google.com (Kenton Varda)'

import difflib
import re

import unittest
from google.protobuf import text_format
from google.protobuf.internal import test_util
from google.protobuf import unittest_pb2
from google.protobuf import unittest_mset_pb2


class TextFormatTest(unittest.TestCase):
  def ReadGolden(self, golden_filename):
    f = test_util.GoldenFile(golden_filename)
    golden_lines = f.readlines()
    f.close()
    return golden_lines

  def CompareToGoldenFile(self, text, golden_filename):
    golden_lines = self.ReadGolden(golden_filename)
    self.CompareToGoldenLines(text, golden_lines)

  def CompareToGoldenText(self, text, golden_text):
    self.CompareToGoldenLines(text, golden_text.splitlines(1))

  def CompareToGoldenLines(self, text, golden_lines):
    actual_lines = text.splitlines(1)
    self.assertEqual(golden_lines, actual_lines,
      "Text doesn't match golden.  Diff:\n" +
      ''.join(difflib.ndiff(golden_lines, actual_lines)))

  def testPrintAllFields(self):
    message = unittest_pb2.TestAllTypes()
    test_util.SetAllFields(message)
    self.CompareToGoldenFile(
      self.RemoveRedundantZeros(text_format.MessageToString(message)),
      'text_format_unittest_data.txt')

  def testPrintAllExtensions(self):
    message = unittest_pb2.TestAllExtensions()
    test_util.SetAllExtensions(message)
    self.CompareToGoldenFile(
      self.RemoveRedundantZeros(text_format.MessageToString(message)),
      'text_format_unittest_extensions_data.txt')

  def testPrintMessageSet(self):
    message = unittest_mset_pb2.TestMessageSetContainer()
    ext1 = unittest_mset_pb2.TestMessageSetExtension1.message_set_extension
    ext2 = unittest_mset_pb2.TestMessageSetExtension2.message_set_extension
    message.message_set.Extensions[ext1].i = 23
    message.message_set.Extensions[ext2].str = 'foo'
    self.CompareToGoldenText(text_format.MessageToString(message),
      'message_set {\n'
      '  [protobuf_unittest.TestMessageSetExtension1] {\n'
      '    i: 23\n'
      '  }\n'
      '  [protobuf_unittest.TestMessageSetExtension2] {\n'
      '    str: \"foo\"\n'
      '  }\n'
      '}\n')

  def testPrintBadEnumValue(self):
    message = unittest_pb2.TestAllTypes()
    message.optional_nested_enum = 100
    message.optional_foreign_enum = 101
    message.optional_import_enum = 102
    self.CompareToGoldenText(
        text_format.MessageToString(message),
        'optional_nested_enum: 100\n'
        'optional_foreign_enum: 101\n'
        'optional_import_enum: 102\n')

  def testPrintBadEnumValueExtensions(self):
    message = unittest_pb2.TestAllExtensions()
    message.Extensions[unittest_pb2.optional_nested_enum_extension] = 100
    message.Extensions[unittest_pb2.optional_foreign_enum_extension] = 101
    message.Extensions[unittest_pb2.optional_import_enum_extension] = 102
    self.CompareToGoldenText(
        text_format.MessageToString(message),
        '[protobuf_unittest.optional_nested_enum_extension]: 100\n'
        '[protobuf_unittest.optional_foreign_enum_extension]: 101\n'
        '[protobuf_unittest.optional_import_enum_extension]: 102\n')

  def testPrintExotic(self):
    message = unittest_pb2.TestAllTypes()
    message.repeated_int64.append(-9223372036854775808)
    message.repeated_uint64.append(18446744073709551615)
    message.repeated_double.append(123.456)
    message.repeated_double.append(1.23e22)
    message.repeated_double.append(1.23e-18)
    message.repeated_string.append('\000\001\a\b\f\n\r\t\v\\\'"')
    message.repeated_string.append(u'\u00fc\ua71f')
    self.CompareToGoldenText(
      self.RemoveRedundantZeros(text_format.MessageToString(message)),
      'repeated_int64: -9223372036854775808\n'
      'repeated_uint64: 18446744073709551615\n'
      'repeated_double: 123.456\n'
      'repeated_double: 1.23e+22\n'
      'repeated_double: 1.23e-18\n'
      'repeated_string: '
        '"\\000\\001\\007\\010\\014\\n\\r\\t\\013\\\\\\\'\\""\n'
      'repeated_string: "\\303\\274\\352\\234\\237"\n')

  def testPrintNestedMessageAsOneLine(self):
    message = unittest_pb2.TestAllTypes()
    msg = message.repeated_nested_message.add()
    msg.bb = 42;
    self.CompareToGoldenText(
        text_format.MessageToString(message, as_one_line=True),
        'repeated_nested_message { bb: 42 }')

  def testPrintRepeatedFieldsAsOneLine(self):
    message = unittest_pb2.TestAllTypes()
    message.repeated_int32.append(1)
    message.repeated_int32.append(1)
    message.repeated_int32.append(3)
    message.repeated_string.append("Google")
    message.repeated_string.append("Zurich")
    self.CompareToGoldenText(
        text_format.MessageToString(message, as_one_line=True),
        'repeated_int32: 1 repeated_int32: 1 repeated_int32: 3 '
        'repeated_string: "Google" repeated_string: "Zurich"')

  def testPrintNestedNewLineInStringAsOneLine(self):
    message = unittest_pb2.TestAllTypes()
    message.optional_string = "a\nnew\nline"
    self.CompareToGoldenText(
        text_format.MessageToString(message, as_one_line=True),
        'optional_string: "a\\nnew\\nline"')

  def testPrintMessageSetAsOneLine(self):
    message = unittest_mset_pb2.TestMessageSetContainer()
    ext1 = unittest_mset_pb2.TestMessageSetExtension1.message_set_extension
    ext2 = unittest_mset_pb2.TestMessageSetExtension2.message_set_extension
    message.message_set.Extensions[ext1].i = 23
    message.message_set.Extensions[ext2].str = 'foo'
    self.CompareToGoldenText(
        text_format.MessageToString(message, as_one_line=True),
        'message_set {'
        ' [protobuf_unittest.TestMessageSetExtension1] {'
        ' i: 23'
        ' }'
        ' [protobuf_unittest.TestMessageSetExtension2] {'
        ' str: \"foo\"'
        ' }'
        ' }')

  def testPrintExoticAsOneLine(self):
    message = unittest_pb2.TestAllTypes()
    message.repeated_int64.append(-9223372036854775808)
    message.repeated_uint64.append(18446744073709551615)
    message.repeated_double.append(123.456)
    message.repeated_double.append(1.23e22)
    message.repeated_double.append(1.23e-18)
    message.repeated_string.append('\000\001\a\b\f\n\r\t\v\\\'"')
    message.repeated_string.append(u'\u00fc\ua71f')
    self.CompareToGoldenText(
      self.RemoveRedundantZeros(
          text_format.MessageToString(message, as_one_line=True)),
      'repeated_int64: -9223372036854775808'
      ' repeated_uint64: 18446744073709551615'
      ' repeated_double: 123.456'
      ' repeated_double: 1.23e+22'
      ' repeated_double: 1.23e-18'
      ' repeated_string: '
      '"\\000\\001\\007\\010\\014\\n\\r\\t\\013\\\\\\\'\\""'
      ' repeated_string: "\\303\\274\\352\\234\\237"')

  def testRoundTripExoticAsOneLine(self):
    message = unittest_pb2.TestAllTypes()
    message.repeated_int64.append(-9223372036854775808)
    message.repeated_uint64.append(18446744073709551615)
    message.repeated_double.append(123.456)
    message.repeated_double.append(1.23e22)
    message.repeated_double.append(1.23e-18)
    message.repeated_string.append('\000\001\a\b\f\n\r\t\v\\\'"')
    message.repeated_string.append(u'\u00fc\ua71f')

    # Test as_utf8 = False.
    wire_text = text_format.MessageToString(
        message, as_one_line=True, as_utf8=False)
    parsed_message = unittest_pb2.TestAllTypes()
    text_format.Merge(wire_text, parsed_message)
    self.assertEquals(message, parsed_message)

    # Test as_utf8 = True.
    wire_text = text_format.MessageToString(
        message, as_one_line=True, as_utf8=True)
    parsed_message = unittest_pb2.TestAllTypes()
    text_format.Merge(wire_text, parsed_message)
    self.assertEquals(message, parsed_message)

  def testPrintRawUtf8String(self):
    message = unittest_pb2.TestAllTypes()
    message.repeated_string.append(u'\u00fc\ua71f')
    text = text_format.MessageToString(message, as_utf8 = True)
    self.CompareToGoldenText(text, 'repeated_string: "\303\274\352\234\237"\n')
    parsed_message = unittest_pb2.TestAllTypes()
    text_format.Merge(text, parsed_message)
    self.assertEquals(message, parsed_message)

  def testMessageToString(self):
    message = unittest_pb2.ForeignMessage()
    message.c = 123
    self.assertEqual('c: 123\n', str(message))

  def RemoveRedundantZeros(self, text):
    # Some platforms print 1e+5 as 1e+005.  This is fine, but we need to remove
    # these zeros in order to match the golden file.
    text = text.replace('e+0','e+').replace('e+0','e+') \
               .replace('e-0','e-').replace('e-0','e-')
    # Floating point fields are printed with .0 suffix even if they are
    # actualy integer numbers.
    text = re.compile('\.0$', re.MULTILINE).sub('', text)
    return text

  def testMergeGolden(self):
    golden_text = '\n'.join(self.ReadGolden('text_format_unittest_data.txt'))
    parsed_message = unittest_pb2.TestAllTypes()
    text_format.Merge(golden_text, parsed_message)

    message = unittest_pb2.TestAllTypes()
    test_util.SetAllFields(message)
    self.assertEquals(message, parsed_message)

  def testMergeGoldenExtensions(self):
    golden_text = '\n'.join(self.ReadGolden(
        'text_format_unittest_extensions_data.txt'))
    parsed_message = unittest_pb2.TestAllExtensions()
    text_format.Merge(golden_text, parsed_message)

    message = unittest_pb2.TestAllExtensions()
    test_util.SetAllExtensions(message)
    self.assertEquals(message, parsed_message)

  def testMergeAllFields(self):
    message = unittest_pb2.TestAllTypes()
    test_util.SetAllFields(message)
    ascii_text = text_format.MessageToString(message)

    parsed_message = unittest_pb2.TestAllTypes()
    text_format.Merge(ascii_text, parsed_message)
    self.assertEqual(message, parsed_message)
    test_util.ExpectAllFieldsSet(self, message)

  def testMergeAllExtensions(self):
    message = unittest_pb2.TestAllExtensions()
    test_util.SetAllExtensions(message)
    ascii_text = text_format.MessageToString(message)

    parsed_message = unittest_pb2.TestAllExtensions()
    text_format.Merge(ascii_text, parsed_message)
    self.assertEqual(message, parsed_message)

  def testMergeMessageSet(self):
    message = unittest_pb2.TestAllTypes()
    text = ('repeated_uint64: 1\n'
            'repeated_uint64: 2\n')
    text_format.Merge(text, message)
    self.assertEqual(1, message.repeated_uint64[0])
    self.assertEqual(2, message.repeated_uint64[1])

    message = unittest_mset_pb2.TestMessageSetContainer()
    text = ('message_set {\n'
            '  [protobuf_unittest.TestMessageSetExtension1] {\n'
            '    i: 23\n'
            '  }\n'
            '  [protobuf_unittest.TestMessageSetExtension2] {\n'
            '    str: \"foo\"\n'
            '  }\n'
            '}\n')
    text_format.Merge(text, message)
    ext1 = unittest_mset_pb2.TestMessageSetExtension1.message_set_extension
    ext2 = unittest_mset_pb2.TestMessageSetExtension2.message_set_extension
    self.assertEquals(23, message.message_set.Extensions[ext1].i)
    self.assertEquals('foo', message.message_set.Extensions[ext2].str)

  def testMergeExotic(self):
    message = unittest_pb2.TestAllTypes()
    text = ('repeated_int64: -9223372036854775808\n'
            'repeated_uint64: 18446744073709551615\n'
            'repeated_double: 123.456\n'
            'repeated_double: 1.23e+22\n'
            'repeated_double: 1.23e-18\n'
            'repeated_string: \n'
            '"\\000\\001\\007\\010\\014\\n\\r\\t\\013\\\\\\\'\\""\n'
            'repeated_string: "foo" \'corge\' "grault"\n'
            'repeated_string: "\\303\\274\\352\\234\\237"\n'
            'repeated_string: "\\xc3\\xbc"\n'
            'repeated_string: "\xc3\xbc"\n')
    text_format.Merge(text, message)

    self.assertEqual(-9223372036854775808, message.repeated_int64[0])
    self.assertEqual(18446744073709551615, message.repeated_uint64[0])
    self.assertEqual(123.456, message.repeated_double[0])
    self.assertEqual(1.23e22, message.repeated_double[1])
    self.assertEqual(1.23e-18, message.repeated_double[2])
    self.assertEqual(
        '\000\001\a\b\f\n\r\t\v\\\'"', message.repeated_string[0])
    self.assertEqual('foocorgegrault', message.repeated_string[1])
    self.assertEqual(u'\u00fc\ua71f', message.repeated_string[2])
    self.assertEqual(u'\u00fc', message.repeated_string[3])

  def testMergeEmptyText(self):
    message = unittest_pb2.TestAllTypes()
    text = ''
    text_format.Merge(text, message)
    self.assertEquals(unittest_pb2.TestAllTypes(), message)

  def testMergeInvalidUtf8(self):
    message = unittest_pb2.TestAllTypes()
    text = 'repeated_string: "\\xc3\\xc3"'
    self.assertRaises(text_format.ParseError, text_format.Merge, text, message)

  def testMergeSingleWord(self):
    message = unittest_pb2.TestAllTypes()
    text = 'foo'
    self.assertRaisesWithMessage(
        text_format.ParseError,
        ('1:1 : Message type "protobuf_unittest.TestAllTypes" has no field named '
         '"foo".'),
        text_format.Merge, text, message)

  def testMergeUnknownField(self):
    message = unittest_pb2.TestAllTypes()
    text = 'unknown_field: 8\n'
    self.assertRaisesWithMessage(
        text_format.ParseError,
        ('1:1 : Message type "protobuf_unittest.TestAllTypes" has no field named '
         '"unknown_field".'),
        text_format.Merge, text, message)

  def testMergeBadExtension(self):
    message = unittest_pb2.TestAllExtensions()
    text = '[unknown_extension]: 8\n'
    self.assertRaisesWithMessage(
        text_format.ParseError,
        '1:2 : Extension "unknown_extension" not registered.',
        text_format.Merge, text, message)
    message = unittest_pb2.TestAllTypes()
    self.assertRaisesWithMessage(
        text_format.ParseError,
        ('1:2 : Message type "protobuf_unittest.TestAllTypes" does not have '
         'extensions.'),
        text_format.Merge, text, message)

  def testMergeGroupNotClosed(self):
    message = unittest_pb2.TestAllTypes()
    text = 'RepeatedGroup: <'
    self.assertRaisesWithMessage(
        text_format.ParseError, '1:16 : Expected ">".',
        text_format.Merge, text, message)

    text = 'RepeatedGroup: {'
    self.assertRaisesWithMessage(
        text_format.ParseError, '1:16 : Expected "}".',
        text_format.Merge, text, message)

  def testMergeEmptyGroup(self):
    message = unittest_pb2.TestAllTypes()
    text = 'OptionalGroup: {}'
    text_format.Merge(text, message)
    self.assertTrue(message.HasField('optionalgroup'))

    message.Clear()

    message = unittest_pb2.TestAllTypes()
    text = 'OptionalGroup: <>'
    text_format.Merge(text, message)
    self.assertTrue(message.HasField('optionalgroup'))

  def testMergeBadEnumValue(self):
    message = unittest_pb2.TestAllTypes()
    text = 'optional_nested_enum: BARR'
    self.assertRaisesWithMessage(
        text_format.ParseError,
        ('1:23 : Enum type "protobuf_unittest.TestAllTypes.NestedEnum" '
         'has no value named BARR.'),
        text_format.Merge, text, message)

    message = unittest_pb2.TestAllTypes()
    text = 'optional_nested_enum: 100'
    self.assertRaisesWithMessage(
        text_format.ParseError,
        ('1:23 : Enum type "protobuf_unittest.TestAllTypes.NestedEnum" '
         'has no value with number 100.'),
        text_format.Merge, text, message)

  def testMergeBadIntValue(self):
    message = unittest_pb2.TestAllTypes()
    text = 'optional_int32: bork'
    self.assertRaisesWithMessage(
        text_format.ParseError,
        ('1:17 : Couldn\'t parse integer: bork'),
        text_format.Merge, text, message)

  def assertRaisesWithMessage(self, e_class, e, func, *args, **kwargs):
    """Same as assertRaises, but also compares the exception message."""
    if hasattr(e_class, '__name__'):
      exc_name = e_class.__name__
    else:
      exc_name = str(e_class)

    try:
      func(*args, **kwargs)
    except e_class as expr:
      if str(expr) != e:
        msg = '%s raised, but with wrong message: "%s" instead of "%s"'
        raise self.failureException(msg % (exc_name,
                                           str(expr).encode('string_escape'),
                                           e.encode('string_escape')))
      return
    else:
      raise self.failureException('%s not raised' % exc_name)


class TokenizerTest(unittest.TestCase):

  def testSimpleTokenCases(self):
    text = ('identifier1:"string1"\n     \n\n'
            'identifier2 : \n \n123  \n  identifier3 :\'string\'\n'
            'identifiER_4 : 1.1e+2 ID5:-0.23 ID6:\'aaaa\\\'bbbb\'\n'
            'ID7 : "aa\\"bb"\n\n\n\n ID8: {A:inf B:-inf C:true D:false}\n'
            'ID9: 22 ID10: -111111111111111111 ID11: -22\n'
            'ID12: 2222222222222222222 ID13: 1.23456f ID14: 1.2e+2f '
            'false_bool:  0 true_BOOL:t \n true_bool1:  1 false_BOOL1:f ' )
    tokenizer = text_format._Tokenizer(text)
    methods = [(tokenizer.ConsumeIdentifier, 'identifier1'),
               ':',
               (tokenizer.ConsumeString, 'string1'),
               (tokenizer.ConsumeIdentifier, 'identifier2'),
               ':',
               (tokenizer.ConsumeInt32, 123),
               (tokenizer.ConsumeIdentifier, 'identifier3'),
               ':',
               (tokenizer.ConsumeString, 'string'),
               (tokenizer.ConsumeIdentifier, 'identifiER_4'),
               ':',
               (tokenizer.ConsumeFloat, 1.1e+2),
               (tokenizer.ConsumeIdentifier, 'ID5'),
               ':',
               (tokenizer.ConsumeFloat, -0.23),
               (tokenizer.ConsumeIdentifier, 'ID6'),
               ':',
               (tokenizer.ConsumeString, 'aaaa\'bbbb'),
               (tokenizer.ConsumeIdentifier, 'ID7'),
               ':',
               (tokenizer.ConsumeString, 'aa\"bb'),
               (tokenizer.ConsumeIdentifier, 'ID8'),
               ':',
               '{',
               (tokenizer.ConsumeIdentifier, 'A'),
               ':',
               (tokenizer.ConsumeFloat, float('inf')),
               (tokenizer.ConsumeIdentifier, 'B'),
               ':',
               (tokenizer.ConsumeFloat, -float('inf')),
               (tokenizer.ConsumeIdentifier, 'C'),
               ':',
               (tokenizer.ConsumeBool, True),
               (tokenizer.ConsumeIdentifier, 'D'),
               ':',
               (tokenizer.ConsumeBool, False),
               '}',
               (tokenizer.ConsumeIdentifier, 'ID9'),
               ':',
               (tokenizer.ConsumeUint32, 22),
               (tokenizer.ConsumeIdentifier, 'ID10'),
               ':',
               (tokenizer.ConsumeInt64, -111111111111111111),
               (tokenizer.ConsumeIdentifier, 'ID11'),
               ':',
               (tokenizer.ConsumeInt32, -22),
               (tokenizer.ConsumeIdentifier, 'ID12'),
               ':',
               (tokenizer.ConsumeUint64, 2222222222222222222),
               (tokenizer.ConsumeIdentifier, 'ID13'),
               ':',
               (tokenizer.ConsumeFloat, 1.23456),
               (tokenizer.ConsumeIdentifier, 'ID14'),
               ':',
               (tokenizer.ConsumeFloat, 1.2e+2),
               (tokenizer.ConsumeIdentifier, 'false_bool'),
               ':',
               (tokenizer.ConsumeBool, False),
               (tokenizer.ConsumeIdentifier, 'true_BOOL'),
               ':',
               (tokenizer.ConsumeBool, True),
               (tokenizer.ConsumeIdentifier, 'true_bool1'),
               ':',
               (tokenizer.ConsumeBool, True),
               (tokenizer.ConsumeIdentifier, 'false_BOOL1'),
               ':',
               (tokenizer.ConsumeBool, False)]

    i = 0
    while not tokenizer.AtEnd():
      m = methods[i]
      if type(m) == str:
        token = tokenizer.token
        self.assertEqual(token, m)
        tokenizer.NextToken()
      else:
        self.assertEqual(m[1], m[0]())
      i += 1

  def testConsumeIntegers(self):
    # This test only tests the failures in the integer parsing methods as well
    # as the '0' special cases.
    int64_max = (1 << 63) - 1
    uint32_max = (1 << 32) - 1
    text = '-1 %d %d' % (uint32_max + 1, int64_max + 1)
    tokenizer = text_format._Tokenizer(text)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeUint32)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeUint64)
    self.assertEqual(-1, tokenizer.ConsumeInt32())

    self.assertRaises(text_format.ParseError, tokenizer.ConsumeUint32)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeInt32)
    self.assertEqual(uint32_max + 1, tokenizer.ConsumeInt64())

    self.assertRaises(text_format.ParseError, tokenizer.ConsumeInt64)
    self.assertEqual(int64_max + 1, tokenizer.ConsumeUint64())
    self.assertTrue(tokenizer.AtEnd())

    text = '-0 -0 0 0'
    tokenizer = text_format._Tokenizer(text)
    self.assertEqual(0, tokenizer.ConsumeUint32())
    self.assertEqual(0, tokenizer.ConsumeUint64())
    self.assertEqual(0, tokenizer.ConsumeUint32())
    self.assertEqual(0, tokenizer.ConsumeUint64())
    self.assertTrue(tokenizer.AtEnd())

  def testConsumeByteString(self):
    text = '"string1\''
    tokenizer = text_format._Tokenizer(text)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeByteString)

    text = 'string1"'
    tokenizer = text_format._Tokenizer(text)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeByteString)

    text = '\n"\\xt"'
    tokenizer = text_format._Tokenizer(text)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeByteString)

    text = '\n"\\"'
    tokenizer = text_format._Tokenizer(text)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeByteString)

    text = '\n"\\x"'
    tokenizer = text_format._Tokenizer(text)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeByteString)

  def testConsumeBool(self):
    text = 'not-a-bool'
    tokenizer = text_format._Tokenizer(text)
    self.assertRaises(text_format.ParseError, tokenizer.ConsumeBool)


if __name__ == '__main__':
  unittest.main()
