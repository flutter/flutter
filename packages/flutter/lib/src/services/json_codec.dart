// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'codec.dart';

/// [MethodCodec] with UTF-8 encoded JSON messages.
///
/// Supported messages are acyclic values of these forms:
///
/// * `null`
/// * [bool]s
/// * [num]s
/// * [String]s
/// * [List]s of supported values
/// * [Map]s from strings to supported values
class JSONCodec implements MethodCodec {
  const JSONCodec();

  @override
  ByteData encodeMessage(dynamic message) => _encodeUTF8(_encodeJSON(message));

  @override
  dynamic decodeMessage(ByteData message) => _decodeJSON(_decodeUTF8(message));

  @override
  ByteData encodeMethodCall(String name, dynamic arguments) {
    assert(name != null);
    return encodeMessage(<String, dynamic>{
      'method': name,
      'args': arguments,
    });
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    final dynamic decoded = decodeMessage(envelope);
    if (decoded is! Map)
      throw new FormatException('Expected envelope Map, got $decoded');
    final String status = decoded['status'];
    final dynamic data = decoded['data'];
    if (status == 'ok')
      return data;
    final String message = decoded['message'];
    if (status is String && message is String)
      throw new PlatformException(code: status, message: message, details: data);
    throw new FormatException('Invalid envelope $decoded');
  }

  ByteData _encodeUTF8(String message) {
    if (message == null)
      return null;
    Uint8List encoded = UTF8.encoder.convert(message);
    return encoded.buffer.asByteData();
  }

  String _decodeUTF8(ByteData message) {
    return message != null ? UTF8.decoder.convert(message.buffer.asUint8List()) : null;
  }

  String _encodeJSON(dynamic message) {
    return message != null ? JSON.encode(message) : null;
  }

  dynamic _decodeJSON(String message) {
    return message != null ? JSON.decode(message) : null;
  }

}

