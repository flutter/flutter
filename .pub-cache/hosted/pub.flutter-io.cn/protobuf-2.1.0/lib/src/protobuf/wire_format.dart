// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

part of protobuf;

const int TAG_TYPE_BITS = 3;
const int TAG_TYPE_MASK = (1 << TAG_TYPE_BITS) - 1;

const int WIRETYPE_VARINT = 0;
const int WIRETYPE_FIXED64 = 1;
const int WIRETYPE_LENGTH_DELIMITED = 2;
const int WIRETYPE_START_GROUP = 3;
const int WIRETYPE_END_GROUP = 4;
const int WIRETYPE_FIXED32 = 5;

int getTagFieldNumber(int tag) => tag >> TAG_TYPE_BITS;

int getTagWireType(int tag) => tag & TAG_TYPE_MASK;

int makeTag(int fieldNumber, int tag) => (fieldNumber << TAG_TYPE_BITS) | tag;

/// Returns true if the wireType can be merged into the given fieldType.
bool _wireTypeMatches(int fieldType, int wireType) {
  switch (PbFieldType._baseType(fieldType)) {
    case PbFieldType._BOOL_BIT:
    case PbFieldType._ENUM_BIT:
    case PbFieldType._INT32_BIT:
    case PbFieldType._INT64_BIT:
    case PbFieldType._SINT32_BIT:
    case PbFieldType._SINT64_BIT:
    case PbFieldType._UINT32_BIT:
    case PbFieldType._UINT64_BIT:
      return wireType == WIRETYPE_VARINT ||
          wireType == WIRETYPE_LENGTH_DELIMITED;
    case PbFieldType._FLOAT_BIT:
    case PbFieldType._FIXED32_BIT:
    case PbFieldType._SFIXED32_BIT:
      return wireType == WIRETYPE_FIXED32 ||
          wireType == WIRETYPE_LENGTH_DELIMITED;
    case PbFieldType._DOUBLE_BIT:
    case PbFieldType._FIXED64_BIT:
    case PbFieldType._SFIXED64_BIT:
      return wireType == WIRETYPE_FIXED64 ||
          wireType == WIRETYPE_LENGTH_DELIMITED;
    case PbFieldType._BYTES_BIT:
    case PbFieldType._STRING_BIT:
    case PbFieldType._MESSAGE_BIT:
      return wireType == WIRETYPE_LENGTH_DELIMITED;
    case PbFieldType._GROUP_BIT:
      return wireType == WIRETYPE_START_GROUP;
    default:
      return false;
  }
}
