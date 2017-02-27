// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A message encoding/decoding mechanism.
///
/// Both operations throw [FormatException], if conversion fails.
abstract class MessageCodec {
  /// Encodes the specified [message] in binary.
  ///
  /// Returns `null` if the message is `null`.
  ByteData encodeMessage(dynamic message);

  /// Decodes the specified [message] from binary.
  ///
  /// Returns `null` if the message is `null`.
  dynamic decodeMessage(ByteData message);
}

/// A message codec that supports method calls and enveloped replies.
///
/// Reply envelopes are binary messages with enough structure that the codec can
/// distinguish between a successful reply and an error. In the former case,
/// the codec must be able to extract the result, possibly `null`. In
/// the latter case, the codec must be able to extract an error code string,
/// a (human-readable) error message string, and a value providing any
/// additional error details, possibly `null`. These data items are used to
/// populate a [PlatformException].
///
/// All operations throw [FormatException], if conversion fails.
abstract class MethodCodec extends MessageCodec {
  /// Encodes the specified method call in binary.
  ///
  /// The [name] of the method must be non-null. The [arguments] may be `null`.
  ByteData encodeMethodCall(String name, dynamic arguments);

  /// Decodes the specified reply [envelope] from binary.
  ///
  /// Throws [PlatformException], if [envelope] represents an error.
  dynamic decodeEnvelope(ByteData envelope);
}


/// Thrown to indicate that a platform interaction resulted in an error.
class PlatformException implements Exception {
  /// Creates a [PlatformException] with the specified error [code] and
  /// [message], and with the optional
  /// error [details] which must be a valid value for the [MessageCodec]
  /// involved in the interaction.
  PlatformException({
    @required this.code,
    @required this.message,
    this.details,
  }) {
    assert(code != null);
  }

  /// A non-`null` error code.
  final String code;

  /// A human-readable error message, possibly `null`.
  final String message;

  /// Error details, possibly `null`.
  final dynamic details;

  @override
  String toString() => 'PlatformException($code, $message, $details)';
}
