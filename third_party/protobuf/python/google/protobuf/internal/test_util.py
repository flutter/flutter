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

"""Utilities for Python proto2 tests.

This is intentionally modeled on C++ code in
//google/protobuf/test_util.*.
"""

__author__ = 'robinson@google.com (Will Robinson)'

import os.path

from google.protobuf import unittest_import_pb2
from google.protobuf import unittest_pb2


def SetAllNonLazyFields(message):
  """Sets every non-lazy field in the message to a unique value.

  Args:
    message: A unittest_pb2.TestAllTypes instance.
  """

  #
  # Optional fields.
  #

  message.optional_int32    = 101
  message.optional_int64    = 102
  message.optional_uint32   = 103
  message.optional_uint64   = 104
  message.optional_sint32   = 105
  message.optional_sint64   = 106
  message.optional_fixed32  = 107
  message.optional_fixed64  = 108
  message.optional_sfixed32 = 109
  message.optional_sfixed64 = 110
  message.optional_float    = 111
  message.optional_double   = 112
  message.optional_bool     = True
  # TODO(robinson): Firmly spec out and test how
  # protos interact with unicode.  One specific example:
  # what happens if we change the literal below to
  # u'115'?  What *should* happen?  Still some discussion
  # to finish with Kenton about bytes vs. strings
  # and forcing everything to be utf8. :-/
  message.optional_string   = '115'
  message.optional_bytes    = '116'

  message.optionalgroup.a = 117
  message.optional_nested_message.bb = 118
  message.optional_foreign_message.c = 119
  message.optional_import_message.d = 120
  message.optional_public_import_message.e = 126

  message.optional_nested_enum = unittest_pb2.TestAllTypes.BAZ
  message.optional_foreign_enum = unittest_pb2.FOREIGN_BAZ
  message.optional_import_enum = unittest_import_pb2.IMPORT_BAZ

  message.optional_string_piece = '124'
  message.optional_cord = '125'

  #
  # Repeated fields.
  #

  message.repeated_int32.append(201)
  message.repeated_int64.append(202)
  message.repeated_uint32.append(203)
  message.repeated_uint64.append(204)
  message.repeated_sint32.append(205)
  message.repeated_sint64.append(206)
  message.repeated_fixed32.append(207)
  message.repeated_fixed64.append(208)
  message.repeated_sfixed32.append(209)
  message.repeated_sfixed64.append(210)
  message.repeated_float.append(211)
  message.repeated_double.append(212)
  message.repeated_bool.append(True)
  message.repeated_string.append('215')
  message.repeated_bytes.append('216')

  message.repeatedgroup.add().a = 217
  message.repeated_nested_message.add().bb = 218
  message.repeated_foreign_message.add().c = 219
  message.repeated_import_message.add().d = 220
  message.repeated_lazy_message.add().bb = 227

  message.repeated_nested_enum.append(unittest_pb2.TestAllTypes.BAR)
  message.repeated_foreign_enum.append(unittest_pb2.FOREIGN_BAR)
  message.repeated_import_enum.append(unittest_import_pb2.IMPORT_BAR)

  message.repeated_string_piece.append('224')
  message.repeated_cord.append('225')

  # Add a second one of each field.
  message.repeated_int32.append(301)
  message.repeated_int64.append(302)
  message.repeated_uint32.append(303)
  message.repeated_uint64.append(304)
  message.repeated_sint32.append(305)
  message.repeated_sint64.append(306)
  message.repeated_fixed32.append(307)
  message.repeated_fixed64.append(308)
  message.repeated_sfixed32.append(309)
  message.repeated_sfixed64.append(310)
  message.repeated_float.append(311)
  message.repeated_double.append(312)
  message.repeated_bool.append(False)
  message.repeated_string.append('315')
  message.repeated_bytes.append('316')

  message.repeatedgroup.add().a = 317
  message.repeated_nested_message.add().bb = 318
  message.repeated_foreign_message.add().c = 319
  message.repeated_import_message.add().d = 320
  message.repeated_lazy_message.add().bb = 327

  message.repeated_nested_enum.append(unittest_pb2.TestAllTypes.BAZ)
  message.repeated_foreign_enum.append(unittest_pb2.FOREIGN_BAZ)
  message.repeated_import_enum.append(unittest_import_pb2.IMPORT_BAZ)

  message.repeated_string_piece.append('324')
  message.repeated_cord.append('325')

  #
  # Fields that have defaults.
  #

  message.default_int32 = 401
  message.default_int64 = 402
  message.default_uint32 = 403
  message.default_uint64 = 404
  message.default_sint32 = 405
  message.default_sint64 = 406
  message.default_fixed32 = 407
  message.default_fixed64 = 408
  message.default_sfixed32 = 409
  message.default_sfixed64 = 410
  message.default_float = 411
  message.default_double = 412
  message.default_bool = False
  message.default_string = '415'
  message.default_bytes = '416'

  message.default_nested_enum = unittest_pb2.TestAllTypes.FOO
  message.default_foreign_enum = unittest_pb2.FOREIGN_FOO
  message.default_import_enum = unittest_import_pb2.IMPORT_FOO

  message.default_string_piece = '424'
  message.default_cord = '425'


def SetAllFields(message):
  SetAllNonLazyFields(message)
  message.optional_lazy_message.bb = 127


def SetAllExtensions(message):
  """Sets every extension in the message to a unique value.

  Args:
    message: A unittest_pb2.TestAllExtensions instance.
  """

  extensions = message.Extensions
  pb2 = unittest_pb2
  import_pb2 = unittest_import_pb2

  #
  # Optional fields.
  #

  extensions[pb2.optional_int32_extension] = 101
  extensions[pb2.optional_int64_extension] = 102
  extensions[pb2.optional_uint32_extension] = 103
  extensions[pb2.optional_uint64_extension] = 104
  extensions[pb2.optional_sint32_extension] = 105
  extensions[pb2.optional_sint64_extension] = 106
  extensions[pb2.optional_fixed32_extension] = 107
  extensions[pb2.optional_fixed64_extension] = 108
  extensions[pb2.optional_sfixed32_extension] = 109
  extensions[pb2.optional_sfixed64_extension] = 110
  extensions[pb2.optional_float_extension] = 111
  extensions[pb2.optional_double_extension] = 112
  extensions[pb2.optional_bool_extension] = True
  extensions[pb2.optional_string_extension] = '115'
  extensions[pb2.optional_bytes_extension] = '116'

  extensions[pb2.optionalgroup_extension].a = 117
  extensions[pb2.optional_nested_message_extension].bb = 118
  extensions[pb2.optional_foreign_message_extension].c = 119
  extensions[pb2.optional_import_message_extension].d = 120
  extensions[pb2.optional_public_import_message_extension].e = 126
  extensions[pb2.optional_lazy_message_extension].bb = 127

  extensions[pb2.optional_nested_enum_extension] = pb2.TestAllTypes.BAZ
  extensions[pb2.optional_nested_enum_extension] = pb2.TestAllTypes.BAZ
  extensions[pb2.optional_foreign_enum_extension] = pb2.FOREIGN_BAZ
  extensions[pb2.optional_import_enum_extension] = import_pb2.IMPORT_BAZ

  extensions[pb2.optional_string_piece_extension] = '124'
  extensions[pb2.optional_cord_extension] = '125'

  #
  # Repeated fields.
  #

  extensions[pb2.repeated_int32_extension].append(201)
  extensions[pb2.repeated_int64_extension].append(202)
  extensions[pb2.repeated_uint32_extension].append(203)
  extensions[pb2.repeated_uint64_extension].append(204)
  extensions[pb2.repeated_sint32_extension].append(205)
  extensions[pb2.repeated_sint64_extension].append(206)
  extensions[pb2.repeated_fixed32_extension].append(207)
  extensions[pb2.repeated_fixed64_extension].append(208)
  extensions[pb2.repeated_sfixed32_extension].append(209)
  extensions[pb2.repeated_sfixed64_extension].append(210)
  extensions[pb2.repeated_float_extension].append(211)
  extensions[pb2.repeated_double_extension].append(212)
  extensions[pb2.repeated_bool_extension].append(True)
  extensions[pb2.repeated_string_extension].append('215')
  extensions[pb2.repeated_bytes_extension].append('216')

  extensions[pb2.repeatedgroup_extension].add().a = 217
  extensions[pb2.repeated_nested_message_extension].add().bb = 218
  extensions[pb2.repeated_foreign_message_extension].add().c = 219
  extensions[pb2.repeated_import_message_extension].add().d = 220
  extensions[pb2.repeated_lazy_message_extension].add().bb = 227

  extensions[pb2.repeated_nested_enum_extension].append(pb2.TestAllTypes.BAR)
  extensions[pb2.repeated_foreign_enum_extension].append(pb2.FOREIGN_BAR)
  extensions[pb2.repeated_import_enum_extension].append(import_pb2.IMPORT_BAR)

  extensions[pb2.repeated_string_piece_extension].append('224')
  extensions[pb2.repeated_cord_extension].append('225')

  # Append a second one of each field.
  extensions[pb2.repeated_int32_extension].append(301)
  extensions[pb2.repeated_int64_extension].append(302)
  extensions[pb2.repeated_uint32_extension].append(303)
  extensions[pb2.repeated_uint64_extension].append(304)
  extensions[pb2.repeated_sint32_extension].append(305)
  extensions[pb2.repeated_sint64_extension].append(306)
  extensions[pb2.repeated_fixed32_extension].append(307)
  extensions[pb2.repeated_fixed64_extension].append(308)
  extensions[pb2.repeated_sfixed32_extension].append(309)
  extensions[pb2.repeated_sfixed64_extension].append(310)
  extensions[pb2.repeated_float_extension].append(311)
  extensions[pb2.repeated_double_extension].append(312)
  extensions[pb2.repeated_bool_extension].append(False)
  extensions[pb2.repeated_string_extension].append('315')
  extensions[pb2.repeated_bytes_extension].append('316')

  extensions[pb2.repeatedgroup_extension].add().a = 317
  extensions[pb2.repeated_nested_message_extension].add().bb = 318
  extensions[pb2.repeated_foreign_message_extension].add().c = 319
  extensions[pb2.repeated_import_message_extension].add().d = 320
  extensions[pb2.repeated_lazy_message_extension].add().bb = 327

  extensions[pb2.repeated_nested_enum_extension].append(pb2.TestAllTypes.BAZ)
  extensions[pb2.repeated_foreign_enum_extension].append(pb2.FOREIGN_BAZ)
  extensions[pb2.repeated_import_enum_extension].append(import_pb2.IMPORT_BAZ)

  extensions[pb2.repeated_string_piece_extension].append('324')
  extensions[pb2.repeated_cord_extension].append('325')

  #
  # Fields with defaults.
  #

  extensions[pb2.default_int32_extension] = 401
  extensions[pb2.default_int64_extension] = 402
  extensions[pb2.default_uint32_extension] = 403
  extensions[pb2.default_uint64_extension] = 404
  extensions[pb2.default_sint32_extension] = 405
  extensions[pb2.default_sint64_extension] = 406
  extensions[pb2.default_fixed32_extension] = 407
  extensions[pb2.default_fixed64_extension] = 408
  extensions[pb2.default_sfixed32_extension] = 409
  extensions[pb2.default_sfixed64_extension] = 410
  extensions[pb2.default_float_extension] = 411
  extensions[pb2.default_double_extension] = 412
  extensions[pb2.default_bool_extension] = False
  extensions[pb2.default_string_extension] = '415'
  extensions[pb2.default_bytes_extension] = '416'

  extensions[pb2.default_nested_enum_extension] = pb2.TestAllTypes.FOO
  extensions[pb2.default_foreign_enum_extension] = pb2.FOREIGN_FOO
  extensions[pb2.default_import_enum_extension] = import_pb2.IMPORT_FOO

  extensions[pb2.default_string_piece_extension] = '424'
  extensions[pb2.default_cord_extension] = '425'


def SetAllFieldsAndExtensions(message):
  """Sets every field and extension in the message to a unique value.

  Args:
    message: A unittest_pb2.TestAllExtensions message.
  """
  message.my_int = 1
  message.my_string = 'foo'
  message.my_float = 1.0
  message.Extensions[unittest_pb2.my_extension_int] = 23
  message.Extensions[unittest_pb2.my_extension_string] = 'bar'


def ExpectAllFieldsAndExtensionsInOrder(serialized):
  """Ensures that serialized is the serialization we expect for a message
  filled with SetAllFieldsAndExtensions().  (Specifically, ensures that the
  serialization is in canonical, tag-number order).
  """
  my_extension_int = unittest_pb2.my_extension_int
  my_extension_string = unittest_pb2.my_extension_string
  expected_strings = []
  message = unittest_pb2.TestFieldOrderings()
  message.my_int = 1  # Field 1.
  expected_strings.append(message.SerializeToString())
  message.Clear()
  message.Extensions[my_extension_int] = 23  # Field 5.
  expected_strings.append(message.SerializeToString())
  message.Clear()
  message.my_string = 'foo'  # Field 11.
  expected_strings.append(message.SerializeToString())
  message.Clear()
  message.Extensions[my_extension_string] = 'bar'  # Field 50.
  expected_strings.append(message.SerializeToString())
  message.Clear()
  message.my_float = 1.0
  expected_strings.append(message.SerializeToString())
  message.Clear()
  expected = ''.join(expected_strings)

  if expected != serialized:
    raise ValueError('Expected %r, found %r' % (expected, serialized))


def ExpectAllFieldsSet(test_case, message):
  """Check all fields for correct values have after Set*Fields() is called."""
  test_case.assertTrue(message.HasField('optional_int32'))
  test_case.assertTrue(message.HasField('optional_int64'))
  test_case.assertTrue(message.HasField('optional_uint32'))
  test_case.assertTrue(message.HasField('optional_uint64'))
  test_case.assertTrue(message.HasField('optional_sint32'))
  test_case.assertTrue(message.HasField('optional_sint64'))
  test_case.assertTrue(message.HasField('optional_fixed32'))
  test_case.assertTrue(message.HasField('optional_fixed64'))
  test_case.assertTrue(message.HasField('optional_sfixed32'))
  test_case.assertTrue(message.HasField('optional_sfixed64'))
  test_case.assertTrue(message.HasField('optional_float'))
  test_case.assertTrue(message.HasField('optional_double'))
  test_case.assertTrue(message.HasField('optional_bool'))
  test_case.assertTrue(message.HasField('optional_string'))
  test_case.assertTrue(message.HasField('optional_bytes'))

  test_case.assertTrue(message.HasField('optionalgroup'))
  test_case.assertTrue(message.HasField('optional_nested_message'))
  test_case.assertTrue(message.HasField('optional_foreign_message'))
  test_case.assertTrue(message.HasField('optional_import_message'))

  test_case.assertTrue(message.optionalgroup.HasField('a'))
  test_case.assertTrue(message.optional_nested_message.HasField('bb'))
  test_case.assertTrue(message.optional_foreign_message.HasField('c'))
  test_case.assertTrue(message.optional_import_message.HasField('d'))

  test_case.assertTrue(message.HasField('optional_nested_enum'))
  test_case.assertTrue(message.HasField('optional_foreign_enum'))
  test_case.assertTrue(message.HasField('optional_import_enum'))

  test_case.assertTrue(message.HasField('optional_string_piece'))
  test_case.assertTrue(message.HasField('optional_cord'))

  test_case.assertEqual(101, message.optional_int32)
  test_case.assertEqual(102, message.optional_int64)
  test_case.assertEqual(103, message.optional_uint32)
  test_case.assertEqual(104, message.optional_uint64)
  test_case.assertEqual(105, message.optional_sint32)
  test_case.assertEqual(106, message.optional_sint64)
  test_case.assertEqual(107, message.optional_fixed32)
  test_case.assertEqual(108, message.optional_fixed64)
  test_case.assertEqual(109, message.optional_sfixed32)
  test_case.assertEqual(110, message.optional_sfixed64)
  test_case.assertEqual(111, message.optional_float)
  test_case.assertEqual(112, message.optional_double)
  test_case.assertEqual(True, message.optional_bool)
  test_case.assertEqual('115', message.optional_string)
  test_case.assertEqual('116', message.optional_bytes)

  test_case.assertEqual(117, message.optionalgroup.a)
  test_case.assertEqual(118, message.optional_nested_message.bb)
  test_case.assertEqual(119, message.optional_foreign_message.c)
  test_case.assertEqual(120, message.optional_import_message.d)
  test_case.assertEqual(126, message.optional_public_import_message.e)
  test_case.assertEqual(127, message.optional_lazy_message.bb)

  test_case.assertEqual(unittest_pb2.TestAllTypes.BAZ,
                        message.optional_nested_enum)
  test_case.assertEqual(unittest_pb2.FOREIGN_BAZ,
                        message.optional_foreign_enum)
  test_case.assertEqual(unittest_import_pb2.IMPORT_BAZ,
                        message.optional_import_enum)

  # -----------------------------------------------------------------

  test_case.assertEqual(2, len(message.repeated_int32))
  test_case.assertEqual(2, len(message.repeated_int64))
  test_case.assertEqual(2, len(message.repeated_uint32))
  test_case.assertEqual(2, len(message.repeated_uint64))
  test_case.assertEqual(2, len(message.repeated_sint32))
  test_case.assertEqual(2, len(message.repeated_sint64))
  test_case.assertEqual(2, len(message.repeated_fixed32))
  test_case.assertEqual(2, len(message.repeated_fixed64))
  test_case.assertEqual(2, len(message.repeated_sfixed32))
  test_case.assertEqual(2, len(message.repeated_sfixed64))
  test_case.assertEqual(2, len(message.repeated_float))
  test_case.assertEqual(2, len(message.repeated_double))
  test_case.assertEqual(2, len(message.repeated_bool))
  test_case.assertEqual(2, len(message.repeated_string))
  test_case.assertEqual(2, len(message.repeated_bytes))

  test_case.assertEqual(2, len(message.repeatedgroup))
  test_case.assertEqual(2, len(message.repeated_nested_message))
  test_case.assertEqual(2, len(message.repeated_foreign_message))
  test_case.assertEqual(2, len(message.repeated_import_message))
  test_case.assertEqual(2, len(message.repeated_nested_enum))
  test_case.assertEqual(2, len(message.repeated_foreign_enum))
  test_case.assertEqual(2, len(message.repeated_import_enum))

  test_case.assertEqual(2, len(message.repeated_string_piece))
  test_case.assertEqual(2, len(message.repeated_cord))

  test_case.assertEqual(201, message.repeated_int32[0])
  test_case.assertEqual(202, message.repeated_int64[0])
  test_case.assertEqual(203, message.repeated_uint32[0])
  test_case.assertEqual(204, message.repeated_uint64[0])
  test_case.assertEqual(205, message.repeated_sint32[0])
  test_case.assertEqual(206, message.repeated_sint64[0])
  test_case.assertEqual(207, message.repeated_fixed32[0])
  test_case.assertEqual(208, message.repeated_fixed64[0])
  test_case.assertEqual(209, message.repeated_sfixed32[0])
  test_case.assertEqual(210, message.repeated_sfixed64[0])
  test_case.assertEqual(211, message.repeated_float[0])
  test_case.assertEqual(212, message.repeated_double[0])
  test_case.assertEqual(True, message.repeated_bool[0])
  test_case.assertEqual('215', message.repeated_string[0])
  test_case.assertEqual('216', message.repeated_bytes[0])

  test_case.assertEqual(217, message.repeatedgroup[0].a)
  test_case.assertEqual(218, message.repeated_nested_message[0].bb)
  test_case.assertEqual(219, message.repeated_foreign_message[0].c)
  test_case.assertEqual(220, message.repeated_import_message[0].d)
  test_case.assertEqual(227, message.repeated_lazy_message[0].bb)

  test_case.assertEqual(unittest_pb2.TestAllTypes.BAR,
                        message.repeated_nested_enum[0])
  test_case.assertEqual(unittest_pb2.FOREIGN_BAR,
                        message.repeated_foreign_enum[0])
  test_case.assertEqual(unittest_import_pb2.IMPORT_BAR,
                        message.repeated_import_enum[0])

  test_case.assertEqual(301, message.repeated_int32[1])
  test_case.assertEqual(302, message.repeated_int64[1])
  test_case.assertEqual(303, message.repeated_uint32[1])
  test_case.assertEqual(304, message.repeated_uint64[1])
  test_case.assertEqual(305, message.repeated_sint32[1])
  test_case.assertEqual(306, message.repeated_sint64[1])
  test_case.assertEqual(307, message.repeated_fixed32[1])
  test_case.assertEqual(308, message.repeated_fixed64[1])
  test_case.assertEqual(309, message.repeated_sfixed32[1])
  test_case.assertEqual(310, message.repeated_sfixed64[1])
  test_case.assertEqual(311, message.repeated_float[1])
  test_case.assertEqual(312, message.repeated_double[1])
  test_case.assertEqual(False, message.repeated_bool[1])
  test_case.assertEqual('315', message.repeated_string[1])
  test_case.assertEqual('316', message.repeated_bytes[1])

  test_case.assertEqual(317, message.repeatedgroup[1].a)
  test_case.assertEqual(318, message.repeated_nested_message[1].bb)
  test_case.assertEqual(319, message.repeated_foreign_message[1].c)
  test_case.assertEqual(320, message.repeated_import_message[1].d)
  test_case.assertEqual(327, message.repeated_lazy_message[1].bb)

  test_case.assertEqual(unittest_pb2.TestAllTypes.BAZ,
                        message.repeated_nested_enum[1])
  test_case.assertEqual(unittest_pb2.FOREIGN_BAZ,
                        message.repeated_foreign_enum[1])
  test_case.assertEqual(unittest_import_pb2.IMPORT_BAZ,
                        message.repeated_import_enum[1])

  # -----------------------------------------------------------------

  test_case.assertTrue(message.HasField('default_int32'))
  test_case.assertTrue(message.HasField('default_int64'))
  test_case.assertTrue(message.HasField('default_uint32'))
  test_case.assertTrue(message.HasField('default_uint64'))
  test_case.assertTrue(message.HasField('default_sint32'))
  test_case.assertTrue(message.HasField('default_sint64'))
  test_case.assertTrue(message.HasField('default_fixed32'))
  test_case.assertTrue(message.HasField('default_fixed64'))
  test_case.assertTrue(message.HasField('default_sfixed32'))
  test_case.assertTrue(message.HasField('default_sfixed64'))
  test_case.assertTrue(message.HasField('default_float'))
  test_case.assertTrue(message.HasField('default_double'))
  test_case.assertTrue(message.HasField('default_bool'))
  test_case.assertTrue(message.HasField('default_string'))
  test_case.assertTrue(message.HasField('default_bytes'))

  test_case.assertTrue(message.HasField('default_nested_enum'))
  test_case.assertTrue(message.HasField('default_foreign_enum'))
  test_case.assertTrue(message.HasField('default_import_enum'))

  test_case.assertEqual(401, message.default_int32)
  test_case.assertEqual(402, message.default_int64)
  test_case.assertEqual(403, message.default_uint32)
  test_case.assertEqual(404, message.default_uint64)
  test_case.assertEqual(405, message.default_sint32)
  test_case.assertEqual(406, message.default_sint64)
  test_case.assertEqual(407, message.default_fixed32)
  test_case.assertEqual(408, message.default_fixed64)
  test_case.assertEqual(409, message.default_sfixed32)
  test_case.assertEqual(410, message.default_sfixed64)
  test_case.assertEqual(411, message.default_float)
  test_case.assertEqual(412, message.default_double)
  test_case.assertEqual(False, message.default_bool)
  test_case.assertEqual('415', message.default_string)
  test_case.assertEqual('416', message.default_bytes)

  test_case.assertEqual(unittest_pb2.TestAllTypes.FOO,
                        message.default_nested_enum)
  test_case.assertEqual(unittest_pb2.FOREIGN_FOO,
                        message.default_foreign_enum)
  test_case.assertEqual(unittest_import_pb2.IMPORT_FOO,
                        message.default_import_enum)

def GoldenFile(filename):
  """Finds the given golden file and returns a file object representing it."""

  # Search up the directory tree looking for the C++ protobuf source code.
  path = '.'
  while os.path.exists(path):
    if os.path.exists(os.path.join(path, 'src/google/protobuf')):
      # Found it.  Load the golden file from the testdata directory.
      full_path = os.path.join(path, 'src/google/protobuf/testdata', filename)
      return open(full_path, 'rb')
    path = os.path.join(path, '..')

  raise RuntimeError(
    'Could not find golden files.  This test must be run from within the '
    'protobuf source package so that it can read test data files from the '
    'C++ source tree.')


def SetAllPackedFields(message):
  """Sets every field in the message to a unique value.

  Args:
    message: A unittest_pb2.TestPackedTypes instance.
  """
  message.packed_int32.extend([601, 701])
  message.packed_int64.extend([602, 702])
  message.packed_uint32.extend([603, 703])
  message.packed_uint64.extend([604, 704])
  message.packed_sint32.extend([605, 705])
  message.packed_sint64.extend([606, 706])
  message.packed_fixed32.extend([607, 707])
  message.packed_fixed64.extend([608, 708])
  message.packed_sfixed32.extend([609, 709])
  message.packed_sfixed64.extend([610, 710])
  message.packed_float.extend([611.0, 711.0])
  message.packed_double.extend([612.0, 712.0])
  message.packed_bool.extend([True, False])
  message.packed_enum.extend([unittest_pb2.FOREIGN_BAR,
                              unittest_pb2.FOREIGN_BAZ])


def SetAllPackedExtensions(message):
  """Sets every extension in the message to a unique value.

  Args:
    message: A unittest_pb2.TestPackedExtensions instance.
  """
  extensions = message.Extensions
  pb2 = unittest_pb2

  extensions[pb2.packed_int32_extension].extend([601, 701])
  extensions[pb2.packed_int64_extension].extend([602, 702])
  extensions[pb2.packed_uint32_extension].extend([603, 703])
  extensions[pb2.packed_uint64_extension].extend([604, 704])
  extensions[pb2.packed_sint32_extension].extend([605, 705])
  extensions[pb2.packed_sint64_extension].extend([606, 706])
  extensions[pb2.packed_fixed32_extension].extend([607, 707])
  extensions[pb2.packed_fixed64_extension].extend([608, 708])
  extensions[pb2.packed_sfixed32_extension].extend([609, 709])
  extensions[pb2.packed_sfixed64_extension].extend([610, 710])
  extensions[pb2.packed_float_extension].extend([611.0, 711.0])
  extensions[pb2.packed_double_extension].extend([612.0, 712.0])
  extensions[pb2.packed_bool_extension].extend([True, False])
  extensions[pb2.packed_enum_extension].extend([unittest_pb2.FOREIGN_BAR,
                                                unittest_pb2.FOREIGN_BAZ])


def SetAllUnpackedFields(message):
  """Sets every field in the message to a unique value.

  Args:
    message: A unittest_pb2.TestUnpackedTypes instance.
  """
  message.unpacked_int32.extend([601, 701])
  message.unpacked_int64.extend([602, 702])
  message.unpacked_uint32.extend([603, 703])
  message.unpacked_uint64.extend([604, 704])
  message.unpacked_sint32.extend([605, 705])
  message.unpacked_sint64.extend([606, 706])
  message.unpacked_fixed32.extend([607, 707])
  message.unpacked_fixed64.extend([608, 708])
  message.unpacked_sfixed32.extend([609, 709])
  message.unpacked_sfixed64.extend([610, 710])
  message.unpacked_float.extend([611.0, 711.0])
  message.unpacked_double.extend([612.0, 712.0])
  message.unpacked_bool.extend([True, False])
  message.unpacked_enum.extend([unittest_pb2.FOREIGN_BAR,
                                unittest_pb2.FOREIGN_BAZ])
