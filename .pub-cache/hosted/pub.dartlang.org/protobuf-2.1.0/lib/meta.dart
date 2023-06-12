// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides metadata about GeneratedMessage and ProtobufEnum to
/// dart-protoc-plugin. (Experimental API; subject to change.)
library protobuf.meta;

// ignore_for_file: constant_identifier_names

// List of names which cannot be used in a subclass of GeneratedMessage.
const GeneratedMessage_reservedNames = <String>[
  '==',
  'GeneratedMessage',
  'Object',
  'addExtension',
  'check',
  'clear',
  'clearExtension',
  'clearField',
  'clone',
  'copyWith',
  'createEmptyInstance',
  'createMapField',
  'createRepeatedField',
  'eventPlugin',
  'extensionsAreInitialized',
  'freeze',
  'getDefaultForField',
  'getExtension',
  'getField',
  'getFieldOrNull',
  'getTagNumber',
  'hasExtension',
  'hasField',
  'hasRequiredFields',
  'hashCode',
  'info_',
  'isFrozen',
  'isInitialized',
  'mergeFromBuffer',
  'mergeFromCodedBufferReader',
  'mergeFromJson',
  'mergeFromJsonMap',
  'mergeFromMessage',
  'mergeFromProto3Json',
  'mergeUnknownFields',
  'noSuchMethod',
  'runtimeType',
  'setExtension',
  'setField',
  'toBuilder',
  'toDebugString',
  'toProto3Json',
  'toString',
  'unknownFields',
  'writeToBuffer',
  'writeToCodedBufferWriter',
  'writeToJson',
  'writeToJsonMap',
  r'$_ensure',
  r'$_get',
  r'$_getI64',
  r'$_getList',
  r'$_getMap',
  r'$_getN',
  r'$_getB',
  r'$_getBF',
  r'$_getI',
  r'$_getIZ',
  r'$_getS',
  r'$_getSZ',
  r'$_has',
  r'$_setBool',
  r'$_setBytes',
  r'$_setDouble',
  r'$_setFloat',
  r'$_setInt64',
  r'$_setSignedInt32',
  r'$_setString',
  r'$_setUnsignedInt32',
  r'$_whichOneof',

  // Names below are no longer reserved and should be removed in the next major
  // release
  'fromBuffer',
  'fromJson',
  r'$_defaultFor',
];

// List of names which cannot be used in a subclass of ProtobufEnum.
const ProtobufEnum_reservedNames = <String>[
  '==',
  'Object',
  'ProtobufEnum',
  'hashCode',
  'noSuchMethod',
  'runtimeType',
  'toString',

  // Names below are no longer reserved and should be removed in the next major
  // release
  'initByValue',
];
