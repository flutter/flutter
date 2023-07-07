// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

class InvalidProtocolBufferException implements Exception {
  final String message;

  InvalidProtocolBufferException._(this.message);

  @override
  String toString() => 'InvalidProtocolBufferException: $message';

  InvalidProtocolBufferException.invalidEndTag()
      : this._('Protocol message end-group tag did not match expected tag.');

  InvalidProtocolBufferException.invalidTag()
      : this._('Protocol message contained an invalid tag (zero).');

  InvalidProtocolBufferException.invalidWireType()
      : this._('Protocol message tag had invalid wire type.');

  InvalidProtocolBufferException.malformedVarint()
      : this._('CodedBufferReader encountered a malformed varint.');

  InvalidProtocolBufferException.recursionLimitExceeded() : this._('''
Protocol message had too many levels of nesting.  May be malicious.
Use CodedBufferReader.setRecursionLimit() to increase the depth limit.
''');

  InvalidProtocolBufferException.truncatedMessage() : this._('''
While parsing a protocol message, the input ended unexpectedly
in the middle of a field.  This could mean either than the
input has been truncated or that an embedded message
misreported its own length.
''');

  InvalidProtocolBufferException.wrongAnyMessage(
      String anyTypeName, unpackerTypeName)
      : this._('''
The type of the Any message ($anyTypeName) does not match the given
unpacker ($unpackerTypeName).
''');
}
