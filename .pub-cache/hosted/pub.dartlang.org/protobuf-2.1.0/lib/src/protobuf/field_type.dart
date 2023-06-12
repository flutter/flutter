// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names,non_constant_identifier_names
part of protobuf;

bool _isRepeated(int fieldType) => (fieldType & PbFieldType._REPEATED_BIT) != 0;

bool _isRequired(int fieldType) => (fieldType & PbFieldType._REQUIRED_BIT) != 0;

bool _isEnum(int fieldType) =>
    PbFieldType._baseType(fieldType) == PbFieldType._ENUM_BIT;

bool _isBytes(int fieldType) =>
    PbFieldType._baseType(fieldType) == PbFieldType._BYTES_BIT;

bool _isGroupOrMessage(int fieldType) =>
    (fieldType & (PbFieldType._GROUP_BIT | PbFieldType._MESSAGE_BIT)) != 0;

bool _isMapField(int fieldType) => (fieldType & PbFieldType._MAP_BIT) != 0;

/// Defines constants and functions for dealing with fieldType bits.
class PbFieldType {
  /// Returns the base field type without any of the required, repeated
  /// and packed bits.
  static int _baseType(int fieldType) =>
      fieldType & ~(_REQUIRED_BIT | _REPEATED_BIT | _PACKED_BIT | _MAP_BIT);

  static MakeDefaultFunc? _defaultForType(int type) {
    switch (type) {
      case _OPTIONAL_BOOL:
      case _REQUIRED_BOOL:
        return _BOOL_FALSE;
      case _OPTIONAL_BYTES:
      case _REQUIRED_BYTES:
        return _BYTES_EMPTY;
      case _OPTIONAL_STRING:
      case _REQUIRED_STRING:
        return _STRING_EMPTY;
      case _OPTIONAL_FLOAT:
      case _REQUIRED_FLOAT:
      case _OPTIONAL_DOUBLE:
      case _REQUIRED_DOUBLE:
        return _DOUBLE_ZERO;
      case _OPTIONAL_INT32:
      case _REQUIRED_INT32:
      case _OPTIONAL_INT64:
      case _REQUIRED_INT64:
      case _OPTIONAL_SINT32:
      case _REQUIRED_SINT32:
      case _OPTIONAL_SINT64:
      case _REQUIRED_SINT64:
      case _OPTIONAL_UINT32:
      case _REQUIRED_UINT32:
      case _OPTIONAL_UINT64:
      case _REQUIRED_UINT64:
      case _OPTIONAL_FIXED32:
      case _REQUIRED_FIXED32:
      case _OPTIONAL_FIXED64:
      case _REQUIRED_FIXED64:
      case _OPTIONAL_SFIXED32:
      case _REQUIRED_SFIXED32:
      case _OPTIONAL_SFIXED64:
      case _REQUIRED_SFIXED64:
        return _INT_ZERO;
      default:
        return null;
    }
  }

  // Closures commonly used by initializers.
  static String _STRING_EMPTY() => '';
  static List<int> _BYTES_EMPTY() => <int>[];
  static bool _BOOL_FALSE() => false;
  static int _INT_ZERO() => 0;
  static double _DOUBLE_ZERO() => 0.0;

  static const int _REQUIRED_BIT = 0x1;
  static const int _REPEATED_BIT = 0x2;
  static const int _PACKED_BIT = 0x4;

  static const int _BOOL_BIT = 0x10;
  static const int _BYTES_BIT = 0x20;
  static const int _STRING_BIT = 0x40;
  static const int _DOUBLE_BIT = 0x80;
  static const int _FLOAT_BIT = 0x100;
  static const int _ENUM_BIT = 0x200;
  static const int _GROUP_BIT = 0x400;
  static const int _INT32_BIT = 0x800;
  static const int _INT64_BIT = 0x1000;
  static const int _SINT32_BIT = 0x2000;
  static const int _SINT64_BIT = 0x4000;
  static const int _UINT32_BIT = 0x8000;
  static const int _UINT64_BIT = 0x10000;
  static const int _FIXED32_BIT = 0x20000;
  static const int _FIXED64_BIT = 0x40000;
  static const int _SFIXED32_BIT = 0x80000;
  static const int _SFIXED64_BIT = 0x100000;
  static const int _MESSAGE_BIT = 0x200000;
  static const int _MAP_BIT = 0x400000;

  static const int _OPTIONAL_BOOL = _BOOL_BIT;
  static const int _OPTIONAL_BYTES = _BYTES_BIT;
  static const int _OPTIONAL_STRING = _STRING_BIT;
  static const int _OPTIONAL_FLOAT = _FLOAT_BIT;
  static const int _OPTIONAL_DOUBLE = _DOUBLE_BIT;
  static const int _OPTIONAL_ENUM = _ENUM_BIT;
  static const int _OPTIONAL_GROUP = _GROUP_BIT;
  static const int _OPTIONAL_INT32 = _INT32_BIT;
  static const int _OPTIONAL_INT64 = _INT64_BIT;
  static const int _OPTIONAL_SINT32 = _SINT32_BIT;
  static const int _OPTIONAL_SINT64 = _SINT64_BIT;
  static const int _OPTIONAL_UINT32 = _UINT32_BIT;
  static const int _OPTIONAL_UINT64 = _UINT64_BIT;
  static const int _OPTIONAL_FIXED32 = _FIXED32_BIT;
  static const int _OPTIONAL_FIXED64 = _FIXED64_BIT;
  static const int _OPTIONAL_SFIXED32 = _SFIXED32_BIT;
  static const int _OPTIONAL_SFIXED64 = _SFIXED64_BIT;
  static const int _OPTIONAL_MESSAGE = _MESSAGE_BIT;

  static const int _REQUIRED_BOOL = _REQUIRED_BIT | _BOOL_BIT;
  static const int _REQUIRED_BYTES = _REQUIRED_BIT | _BYTES_BIT;
  static const int _REQUIRED_STRING = _REQUIRED_BIT | _STRING_BIT;
  static const int _REQUIRED_FLOAT = _REQUIRED_BIT | _FLOAT_BIT;
  static const int _REQUIRED_DOUBLE = _REQUIRED_BIT | _DOUBLE_BIT;
  static const int _REQUIRED_ENUM = _REQUIRED_BIT | _ENUM_BIT;
  static const int _REQUIRED_GROUP = _REQUIRED_BIT | _GROUP_BIT;
  static const int _REQUIRED_INT32 = _REQUIRED_BIT | _INT32_BIT;
  static const int _REQUIRED_INT64 = _REQUIRED_BIT | _INT64_BIT;
  static const int _REQUIRED_SINT32 = _REQUIRED_BIT | _SINT32_BIT;
  static const int _REQUIRED_SINT64 = _REQUIRED_BIT | _SINT64_BIT;
  static const int _REQUIRED_UINT32 = _REQUIRED_BIT | _UINT32_BIT;
  static const int _REQUIRED_UINT64 = _REQUIRED_BIT | _UINT64_BIT;
  static const int _REQUIRED_FIXED32 = _REQUIRED_BIT | _FIXED32_BIT;
  static const int _REQUIRED_FIXED64 = _REQUIRED_BIT | _FIXED64_BIT;
  static const int _REQUIRED_SFIXED32 = _REQUIRED_BIT | _SFIXED32_BIT;
  static const int _REQUIRED_SFIXED64 = _REQUIRED_BIT | _SFIXED64_BIT;
  static const int _REQUIRED_MESSAGE = _REQUIRED_BIT | _MESSAGE_BIT;

  static const int _REPEATED_BOOL = _REPEATED_BIT | _BOOL_BIT;
  static const int _REPEATED_BYTES = _REPEATED_BIT | _BYTES_BIT;
  static const int _REPEATED_STRING = _REPEATED_BIT | _STRING_BIT;
  static const int _REPEATED_FLOAT = _REPEATED_BIT | _FLOAT_BIT;
  static const int _REPEATED_DOUBLE = _REPEATED_BIT | _DOUBLE_BIT;
  static const int _REPEATED_ENUM = _REPEATED_BIT | _ENUM_BIT;
  static const int _REPEATED_GROUP = _REPEATED_BIT | _GROUP_BIT;
  static const int _REPEATED_INT32 = _REPEATED_BIT | _INT32_BIT;
  static const int _REPEATED_INT64 = _REPEATED_BIT | _INT64_BIT;
  static const int _REPEATED_SINT32 = _REPEATED_BIT | _SINT32_BIT;
  static const int _REPEATED_SINT64 = _REPEATED_BIT | _SINT64_BIT;
  static const int _REPEATED_UINT32 = _REPEATED_BIT | _UINT32_BIT;
  static const int _REPEATED_UINT64 = _REPEATED_BIT | _UINT64_BIT;
  static const int _REPEATED_FIXED32 = _REPEATED_BIT | _FIXED32_BIT;
  static const int _REPEATED_FIXED64 = _REPEATED_BIT | _FIXED64_BIT;
  static const int _REPEATED_SFIXED32 = _REPEATED_BIT | _SFIXED32_BIT;
  static const int _REPEATED_SFIXED64 = _REPEATED_BIT | _SFIXED64_BIT;
  static const int _REPEATED_MESSAGE = _REPEATED_BIT | _MESSAGE_BIT;

  static const int _PACKED_BOOL = _REPEATED_BIT | _PACKED_BIT | _BOOL_BIT;
  static const int _PACKED_FLOAT = _REPEATED_BIT | _PACKED_BIT | _FLOAT_BIT;
  static const int _PACKED_DOUBLE = _REPEATED_BIT | _PACKED_BIT | _DOUBLE_BIT;
  static const int _PACKED_ENUM = _REPEATED_BIT | _PACKED_BIT | _ENUM_BIT;
  static const int _PACKED_INT32 = _REPEATED_BIT | _PACKED_BIT | _INT32_BIT;
  static const int _PACKED_INT64 = _REPEATED_BIT | _PACKED_BIT | _INT64_BIT;
  static const int _PACKED_SINT32 = _REPEATED_BIT | _PACKED_BIT | _SINT32_BIT;
  static const int _PACKED_SINT64 = _REPEATED_BIT | _PACKED_BIT | _SINT64_BIT;
  static const int _PACKED_UINT32 = _REPEATED_BIT | _PACKED_BIT | _UINT32_BIT;
  static const int _PACKED_UINT64 = _REPEATED_BIT | _PACKED_BIT | _UINT64_BIT;
  static const int _PACKED_FIXED32 = _REPEATED_BIT | _PACKED_BIT | _FIXED32_BIT;
  static const int _PACKED_FIXED64 = _REPEATED_BIT | _PACKED_BIT | _FIXED64_BIT;
  static const int _PACKED_SFIXED32 =
      _REPEATED_BIT | _PACKED_BIT | _SFIXED32_BIT;
  static const int _PACKED_SFIXED64 =
      _REPEATED_BIT | _PACKED_BIT | _SFIXED64_BIT;

  static const int _MAP = _MAP_BIT | _MESSAGE_BIT;
  // Short names for use in generated code.

  // _O_ptional.
  static const int OB = _OPTIONAL_BOOL;
  static const int OY = _OPTIONAL_BYTES;
  static const int OS = _OPTIONAL_STRING;
  static const int OF = _OPTIONAL_FLOAT;
  static const int OD = _OPTIONAL_DOUBLE;
  static const int OE = _OPTIONAL_ENUM;
  static const int OG = _OPTIONAL_GROUP;
  static const int O3 = _OPTIONAL_INT32;
  static const int O6 = _OPTIONAL_INT64;
  static const int OS3 = _OPTIONAL_SINT32;
  static const int OS6 = _OPTIONAL_SINT64;
  static const int OU3 = _OPTIONAL_UINT32;
  static const int OU6 = _OPTIONAL_UINT64;
  static const int OF3 = _OPTIONAL_FIXED32;
  static const int OF6 = _OPTIONAL_FIXED64;
  static const int OSF3 = _OPTIONAL_SFIXED32;
  static const int OSF6 = _OPTIONAL_SFIXED64;
  static const int OM = _OPTIONAL_MESSAGE;

  // re_Q_uired.
  static const int QB = _REQUIRED_BOOL;
  static const int QY = _REQUIRED_BYTES;
  static const int QS = _REQUIRED_STRING;
  static const int QF = _REQUIRED_FLOAT;
  static const int QD = _REQUIRED_DOUBLE;
  static const int QE = _REQUIRED_ENUM;
  static const int QG = _REQUIRED_GROUP;
  static const int Q3 = _REQUIRED_INT32;
  static const int Q6 = _REQUIRED_INT64;
  static const int QS3 = _REQUIRED_SINT32;
  static const int QS6 = _REQUIRED_SINT64;
  static const int QU3 = _REQUIRED_UINT32;
  static const int QU6 = _REQUIRED_UINT64;
  static const int QF3 = _REQUIRED_FIXED32;
  static const int QF6 = _REQUIRED_FIXED64;
  static const int QSF3 = _REQUIRED_SFIXED32;
  static const int QSF6 = _REQUIRED_SFIXED64;
  static const int QM = _REQUIRED_MESSAGE;

  // re_P_eated.
  static const int PB = _REPEATED_BOOL;
  static const int PY = _REPEATED_BYTES;
  static const int PS = _REPEATED_STRING;
  static const int PF = _REPEATED_FLOAT;
  static const int PD = _REPEATED_DOUBLE;
  static const int PE = _REPEATED_ENUM;
  static const int PG = _REPEATED_GROUP;
  static const int P3 = _REPEATED_INT32;
  static const int P6 = _REPEATED_INT64;
  static const int PS3 = _REPEATED_SINT32;
  static const int PS6 = _REPEATED_SINT64;
  static const int PU3 = _REPEATED_UINT32;
  static const int PU6 = _REPEATED_UINT64;
  static const int PF3 = _REPEATED_FIXED32;
  static const int PF6 = _REPEATED_FIXED64;
  static const int PSF3 = _REPEATED_SFIXED32;
  static const int PSF6 = _REPEATED_SFIXED64;
  static const int PM = _REPEATED_MESSAGE;

  // pac_K_ed.
  static const int KB = _PACKED_BOOL;
  static const int KE = _PACKED_ENUM;
  static const int KF = _PACKED_FLOAT;
  static const int KD = _PACKED_DOUBLE;
  static const int K3 = _PACKED_INT32;
  static const int K6 = _PACKED_INT64;
  static const int KS3 = _PACKED_SINT32;
  static const int KS6 = _PACKED_SINT64;
  static const int KU3 = _PACKED_UINT32;
  static const int KU6 = _PACKED_UINT64;
  static const int KF3 = _PACKED_FIXED32;
  static const int KF6 = _PACKED_FIXED64;
  static const int KSF3 = _PACKED_SFIXED32;
  static const int KSF6 = _PACKED_SFIXED64;

  static const int M = _MAP;
}
