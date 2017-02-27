// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;

import 'message_codec.dart';

/// [MessageCodec] with unencoded binary messages represented using [ByteData].
class BinaryCodec implements MessageCodec<ByteData> {
  const BinaryCodec();

  @override
  ByteData decodeMessage(ByteData message) => message;

  @override
  ByteData encodeMessage(ByteData message) => message;
}

/// [MessageCodec] with UTF-8 encoded String messages.
class StringCodec implements MessageCodec<String> {
  const StringCodec();

  @override
  String decodeMessage(ByteData message) {
    if (message == null)
      return null;
    return UTF8.decoder.convert(message.buffer.asUint8List());
  }

  @override
  ByteData encodeMessage(String message) {
    if (message == null)
      return null;
    final Uint8List encoded = UTF8.encoder.convert(message);
    return encoded.buffer.asByteData();
  }
}

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
  // The codec serializes supported values, method calls, and result envelopes
  // as outlined below. This format must match the Android and iOS counterparts.
  //
  // * Values are serialized as defined by the JSON codec.
  // * Method calls are serialized as two-element lists with the method name
  //   string as first element and the method call arguments as the second.
  // * Reply envelopes are serialized as either:
  //   * one-element lists containing the successful result as its single
  //     element, or
  //   * three-element lists containing, in order, an error code String, an
  //     error message String, and an error details value.
  const JSONCodec();

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null)
      return null;
    return const StringCodec().encodeMessage(JSON.encode(message));
  }

  @override
  dynamic decodeMessage(ByteData message) {
    if (message == null)
      return message;
    return JSON.decode(const StringCodec().decodeMessage(message));
  }

  @override
  ByteData encodeMethodCall(String name, dynamic arguments) {
    assert(name != null);
    return encodeMessage(<dynamic>[name, arguments]);
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
}

/// [MethodCodec] using the Flutter standard binary message encoding.
///
/// The standard codec is guaranteed to be compatible with the corresponding
/// standard codec for Flutter channels on the host platform. These parts of the
/// Flutter SDK are evolved synchronously.
///
/// Supported messages are acyclic values of these forms:
///
/// * `null`
/// * [bool]s
/// * [num]s
/// * [String]s
/// * [Uint8List]s, [Int32List]s, [Int64List]s, [Float64List]s
/// * [List]s of supported values
/// * [Map]s from supported values to supported values
class StandardCodec implements MethodCodec {
  // The codec serializes supported values, method calls, and result envelopes
  // as outlined below. This format must match the Android and iOS counterparts.
  //
  // Values
  //
  // * A single byte with one of the constant values below determines the
  //   type of the value.
  // * The serialization of the value itself follows the type byte.
  // * Lengths and sizes of serialized parts are encoded using an expanding
  //   format optimized for the common case of small non-negative integers:
  //   * values 0..<254 using one byte with that value;
  //   * values 254..<2^16 using three bytes, the first of which is 254, the
  //     next two the usual big-endian unsigned representation of the value;
  //   * values 2^16..<2^32 using five bytes, the first of which is 255, the
  //     next four the usual big-endian unsigned representation of the value.
  // * null, true, and false have empty serialization; they are encoded directly
  //   in the type byte (using _kNull, _kTrue, _kFalse)
  // * Integers representable in 32 bits are encoded using 4 bytes big-endian,
  //   two's complement representation.
  // * Larger integers representable in 64 bits are encoded using 8 bytes
  //   big-endian, two's complement representation.
  // * Still larger integers are encoded using their hexadecimal string
  //   representation. First the length of that is encoded in the expanding
  //   format, then follows the UTF-8 representation of the hex string.
  // * doubles are encoded using the IEEE 754 64-bit double-precision binary
  //   format.
  // * Strings are encoded using their UTF-8 representation. First the length
  //   of that in bytes is encoded using the expanding format, then follows the
  //   UTF-8 encoding itself.
  // * Uint8Lists, Int32Lists, Int64Lists, and Float64Lists are encoded by first
  //   encoding the list's element count in the expanding format, then the
  //   encoding of the list elements themselves, end-to-end with no additional
  //   type information, using big-endian two's complement or IEEE 754 as
  //   applicable.
  // * Lists are encoded by first encoding their length in the expanding format,
  //   then follows the recursive encoding of each element value, including the
  //   type byte (Lists are assumed to be heterogeneous).
  // * Maps are encoded by first encoding their length in the expanding format,
  //   then follows the recursive encoding of each key/value pair, including the
  //   type byte for both (Maps are assumed to be heterogeneous).
  //
  // Method calls
  //
  // Method calls are encoded using the concatenation of the standard encoding
  // of the method name String and the arguments value.
  //
  // Reply envelopes
  //
  // Reply envelopes are encoded using first a single byte to distinguish the
  // success case (0) from the error case (1). Then follows:
  // * In the success case, the standard encoding of the result value.
  // * In the error case, the concatenation of the standard encoding of the
  //   error code string, the error message string, and the error details value.
  static const int _kNull = 0;
  static const int _kTrue = 1;
  static const int _kFalse = 2;
  static const int _kInt32 = 3;
  static const int _kInt64 = 4;
  static const int _kLargeInt = 5;
  static const int _kFloat64 = 6;
  static const int _kString = 7;
  static const int _kUint8List = 8;
  static const int _kInt32List = 9;
  static const int _kInt64List = 10;
  static const int _kFloat64List = 11;
  static const int _kList = 12;
  static const int _kMap = 13;

  const StandardCodec();

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null) {
      return null;
    }
    final WriteBuffer buffer = new WriteBuffer();
    _writeValue(buffer, message);
    return buffer.done();
  }

  @override
  dynamic decodeMessage(ByteData message) {
    if (message == null) {
      return null;
    }
    final ReadBuffer buffer = new ReadBuffer(message);
    final dynamic result = _readValue(buffer);
    if (buffer.hasRemaining)
      throw new FormatException('Message corrupted');
    return result;
  }

  void _writeSize(WriteBuffer buffer, int value) {
    assert(0 <= value && value < 0xffffffff);
    if (value < 254) {
      buffer.putUint8(value);
    } else if (value < 0xffff) {
      buffer.putUint8(254);
      buffer.putUint8(value >> 8);
      buffer.putUint8(value & 0xff);
    } else {
      buffer.putUint8(255);
      buffer.putUint8(value >> 24);
      buffer.putUint8((value >> 16) & 0xff);
      buffer.putUint8((value >> 8) & 0xff);
      buffer.putUint8(value & 0xff);
    }
  }

  void _writeValue(WriteBuffer buffer, dynamic value) {
    if (value == null) {
      buffer.putUint8(_kNull);
    } else if (value is bool) {
      buffer.putUint8(value ? _kTrue : _kFalse);
    } else if (value is int) {
      if (-0x7fffffff <= value && value < 0x7fffffff) {
        buffer.putUint8(_kInt32);
        buffer.putInt32(value);
      }
      else if (-0x7fffffffffffffff <= value && value < 0x7fffffffffffffff) {
        buffer.putUint8(_kInt64);
        buffer.putInt64(value);
      }
      else {
        buffer.putUint8(_kLargeInt);
        final List<int> hex = UTF8.encoder.convert(value.toRadixString(16));
        _writeSize(buffer, hex.length);
        buffer.putUint8List(hex);
      }
    } else if (value is double) {
      buffer.putUint8(_kFloat64);
      buffer.putFloat64(value);
    } else if (value is String) {
      buffer.putUint8(_kString);
      final List<int> bytes = UTF8.encoder.convert(value);
      _writeSize(buffer, bytes.length);
      buffer.putUint8List(bytes);
    } else if (value is Uint8List) {
      buffer.putUint8(_kUint8List);
      _writeSize(buffer, value.length);
      buffer.putUint8List(value);
    } else if (value is Int32List) {
      buffer.putUint8(_kInt32List);
      _writeSize(buffer, value.length);
      buffer.putInt32List(value);
    } else if (value is Int64List) {
      buffer.putUint8(_kInt64List);
      _writeSize(buffer, value.length);
      buffer.putInt64List(value);
    } else if (value is Float64List) {
      buffer.putUint8(_kFloat64List);
      _writeSize(buffer, value.length);
      buffer.putFloat64List(value);
    } else if (value is List) {
      buffer.putUint8(_kList);
      _writeSize(buffer, value.length);
      for (final dynamic item in value) {
        _writeValue(buffer, item);
      }
    } else if (value is Map) {
      buffer.putUint8(_kMap);
      _writeSize(buffer, value.length);
      value.forEach((dynamic key, dynamic value) {
        _writeValue(buffer, key);
        _writeValue(buffer, value);
      });
    } else {
      throw new ArgumentError.value(value);
    }
  }

  int _readSize(ReadBuffer buffer) {
    final int value = buffer.getUint8();
    if (value < 254) {
      return value;
    } else if (value == 254) {
      return (buffer.getUint8() << 8)
      |  buffer.getUint8();
    } else {
      return (buffer.getUint8() << 24)
      | (buffer.getUint8() << 16)
      | (buffer.getUint8() << 8)
      |  buffer.getUint8();
    }
  }

  dynamic _readValue(ReadBuffer buffer) {
    if (!buffer.hasRemaining)
      throw throw new FormatException('Message corrupted');
    dynamic result;
    switch (buffer.getUint8()) {
      case _kNull:
        result = null;
        break;
      case _kTrue:
        result = true;
        break;
      case _kFalse:
        result = false;
        break;
      case _kInt32:
        result = buffer.getInt32();
        break;
      case _kInt64:
        result = buffer.getInt64();
        break;
      case _kLargeInt:
        final int length = _readSize(buffer);
        final String hex = UTF8.decoder.convert(buffer.getUint8List(length));
        result = int.parse(hex, radix: 16);
        break;
      case _kFloat64:
        result = buffer.getFloat64();
        break;
      case _kString:
        final int length = _readSize(buffer);
        result = UTF8.decoder.convert(buffer.getUint8List(length));
        break;
      case _kUint8List:
        final int length = _readSize(buffer);
        result = buffer.getUint8List(length);
        break;
      case _kInt32List:
        final int length = _readSize(buffer);
        result = buffer.getInt32List(length);
        break;
      case _kInt64List:
        final int length = _readSize(buffer);
        result = buffer.getInt64List(length);
        break;
      case _kFloat64List:
        final int length = _readSize(buffer);
        result = buffer.getFloat64List(length);
        break;
      case _kList:
        final int length = _readSize(buffer);
        result = new List<dynamic>(length);
        for (int i = 0; i < length; i++) {
          result[i] = _readValue(buffer);
        }
        break;
      case _kMap:
        final int length = _readSize(buffer);
        result = new Map<dynamic, dynamic>();
        for (int i = 0; i < length; i++) {
          result[_readValue(buffer)] = _readValue(buffer);
        }
        break;
      default: throw new FormatException('Message corrupted');
    }
    return result;
  }

  @override
  ByteData encodeMethodCall(String name, dynamic arguments) {
    assert(name != null);
    final WriteBuffer buffer = new WriteBuffer();
    _writeValue(buffer, name);
    _writeValue(buffer, arguments);
    return buffer.done();
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    // First byte is zero in success case, and non-zero otherwise.
    if (envelope == null || envelope.lengthInBytes == 0)
      throw new FormatException('Expected envelope, got nothing');
    final ReadBuffer buffer = new ReadBuffer(envelope);
    if (buffer.getUint8() == 0)
      return _readValue(buffer);
    final dynamic errorCode = _readValue(buffer);
    final dynamic errorMessage = _readValue(buffer);
    final dynamic errorDetails = _readValue(buffer);
    if (errorCode is String && (errorMessage == null || errorMessage is String))
      throw new PlatformException(code: errorCode, message: errorMessage, details: errorDetails);
    else
      throw new FormatException('Invalid envelope');
  }
}
