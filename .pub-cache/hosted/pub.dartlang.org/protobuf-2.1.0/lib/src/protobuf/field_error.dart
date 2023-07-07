// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

/// Returns the error message for an invalid field value,
/// or null if it's valid.
///
/// For enums, group, and message fields, this check is only approximate,
/// because the exact type isn't included in [fieldType].
String? _getFieldError(int fieldType, var value) {
  switch (PbFieldType._baseType(fieldType)) {
    case PbFieldType._BOOL_BIT:
      if (value is! bool) return 'not type bool';
      return null;
    case PbFieldType._BYTES_BIT:
      if (value is! List) return 'not List';
      return null;
    case PbFieldType._STRING_BIT:
      if (value is! String) return 'not type String';
      return null;
    case PbFieldType._FLOAT_BIT:
      if (value is! double) return 'not type double';
      if (!_isFloat32(value)) return 'out of range for float';
      return null;
    case PbFieldType._DOUBLE_BIT:
      if (value is! double) return 'not type double';
      return null;
    case PbFieldType._ENUM_BIT:
      if (value is! ProtobufEnum) return 'not type ProtobufEnum';
      return null;

    case PbFieldType._INT32_BIT:
    case PbFieldType._SINT32_BIT:
    case PbFieldType._SFIXED32_BIT:
      if (value is! int) return 'not type int';
      if (!_isSigned32(value)) return 'out of range for signed 32-bit int';
      return null;

    case PbFieldType._UINT32_BIT:
    case PbFieldType._FIXED32_BIT:
      if (value is! int) return 'not type int';
      if (!_isUnsigned32(value)) return 'out of range for unsigned 32-bit int';
      return null;

    case PbFieldType._INT64_BIT:
    case PbFieldType._SINT64_BIT:
    case PbFieldType._UINT64_BIT:
    case PbFieldType._FIXED64_BIT:
    case PbFieldType._SFIXED64_BIT:
      // We always use the full range of the same Dart type.
      // It's up to the caller to treat the Int64 as signed or unsigned.
      // See: https://github.com/google/protobuf.dart/issues/44
      if (value is! Int64) return 'not Int64';
      return null;

    case PbFieldType._GROUP_BIT:
    case PbFieldType._MESSAGE_BIT:
      if (value is! GeneratedMessage) return 'not a GeneratedMessage';
      return null;
    default:
      return 'field has unknown type $fieldType';
  }
}

// entry points for generated code

// generated checkItem for message, group, enum calls this
void checkItemFailed(val, String className) {
  throw ArgumentError('Value ($val) is not an instance of $className');
}

/// Returns a function for validating items in a repeated field.
///
/// For most types this is a not-null check, except for floats, and signed and
/// unsigned 32 bit ints where there also is a range check.
CheckFunc getCheckFunction(int fieldType) {
  switch (fieldType & ~0x7) {
    case PbFieldType._BOOL_BIT:
    case PbFieldType._BYTES_BIT:
    case PbFieldType._STRING_BIT:
    case PbFieldType._DOUBLE_BIT:
    case PbFieldType._ENUM_BIT:
    case PbFieldType._GROUP_BIT:
    case PbFieldType._MESSAGE_BIT:

    case PbFieldType._INT64_BIT:
    case PbFieldType._SINT64_BIT:
    case PbFieldType._SFIXED64_BIT:
    case PbFieldType._UINT64_BIT:
    case PbFieldType._FIXED64_BIT:
      // We always use the full range of the same Dart type.
      // It's up to the caller to treat the Int64 as signed or unsigned.
      // See: https://github.com/google/protobuf.dart/issues/44
      return _checkNotNull;

    case PbFieldType._FLOAT_BIT:
      return _checkFloat;

    case PbFieldType._INT32_BIT:
    case PbFieldType._SINT32_BIT:
    case PbFieldType._SFIXED32_BIT:
      return _checkSigned32;

    case PbFieldType._UINT32_BIT:
    case PbFieldType._FIXED32_BIT:
      return _checkUnsigned32;
  }
  throw ArgumentError('check function not implemented: $fieldType');
}

// check functions for repeated fields

void _checkNotNull(Object? val) {
  if (val == null) {
    throw ArgumentError("Can't add a null to a repeated field");
  }
}

void _checkFloat(Object? val) {
  if (!_isFloat32(val as double)) throw _createFieldRangeError(val, 'a float');
}

void _checkSigned32(Object? val) {
  if (!_isSigned32(val as int)) {
    throw _createFieldRangeError(val, 'a signed int32');
  }
}

void _checkUnsigned32(Object? val) {
  if (!_isUnsigned32(val as int)) {
    throw _createFieldRangeError(val, 'an unsigned int32');
  }
}

RangeError _createFieldRangeError(val, String wantedType) =>
    RangeError('Value ($val) is not $wantedType');

bool _isSigned32(int value) => (-2147483648 <= value) && (value <= 2147483647);

bool _isUnsigned32(int value) => (0 <= value) && (value <= 4294967295);

bool _isFloat32(double value) =>
    value.isNaN ||
    value.isInfinite ||
    (-3.4028234663852886E38 <= value) && (value <= 3.4028234663852886E38);
