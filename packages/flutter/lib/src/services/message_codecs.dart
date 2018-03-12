// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer, required;

import 'message_codec.dart';

/// [MessageCodec] with unencoded binary messages represented using [ByteData].
///
/// On Android, messages will be represented using `java.nio.ByteBuffer`.
/// On iOS, messages will be represented using `NSData`.
class BinaryCodec implements MessageCodec<ByteData> {
  /// Creates a [MessageCodec] with unencoded binary messages represented using
  /// [ByteData].
  const BinaryCodec();

  @override
  ByteData decodeMessage(ByteData message) => message;

  @override
  ByteData encodeMessage(ByteData message) => message;
}

/// [MessageCodec] with UTF-8 encoded String messages.
///
/// On Android, messages will be represented using `java.util.String`.
/// On iOS, messages will be represented using `NSString`.
class StringCodec implements MessageCodec<String> {
  /// Creates a [MessageCodec] with UTF-8 encoded String messages.
  const StringCodec();

  @override
  String decodeMessage(ByteData message) {
    if (message == null)
      return null;
    return utf8.decoder.convert(message.buffer.asUint8List());
  }

  @override
  ByteData encodeMessage(String message) {
    if (message == null)
      return null;
    final Uint8List encoded = utf8.encoder.convert(message);
    return encoded.buffer.asByteData();
  }
}

/// [MessageCodec] with UTF-8 encoded JSON messages.
///
/// Supported messages are acyclic values of these forms:
///
///  * null
///  * [bool]s
///  * [num]s
///  * [String]s
///  * [List]s of supported values
///  * [Map]s from strings to supported values
///
/// On Android, messages are decoded using the `org.json` library.
/// On iOS, messages are decoded using the `NSJSONSerialization` library.
/// In both cases, the use of top-level simple messages (null, [bool], [num],
/// and [String]) is supported (by the Flutter SDK). The decoded value will be
/// null/nil for null, and identical to what would result from decoding a
/// singleton JSON array with a Boolean, number, or string value, and then
/// extracting its single element.
class JSONMessageCodec implements MessageCodec<dynamic> {
  // The codec serializes messages as defined by the JSON codec of the
  // dart:convert package. The format used must match the Android and
  // iOS counterparts.

  /// Creates a [MessageCodec] with UTF-8 encoded JSON messages.
  const JSONMessageCodec();

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null)
      return null;
    return const StringCodec().encodeMessage(json.encode(message));
  }

  @override
  dynamic decodeMessage(ByteData message) {
    if (message == null)
      return message;
    return json.decode(const StringCodec().decodeMessage(message));
  }
}

/// [MethodCodec] with UTF-8 encoded JSON method calls and result envelopes.
///
/// Values supported as method arguments and result payloads are those supported
/// by [JSONMessageCodec].
class JSONMethodCodec implements MethodCodec {
  // The codec serializes method calls, and result envelopes as outlined below.
  // This format must match the Android and iOS counterparts.
  //
  // * Individual values are serialized as defined by the JSON codec of the
  //   dart:convert package.
  // * Method calls are serialized as two-element maps, with the method name
  //   keyed by 'method' and the arguments keyed by 'args'.
  // * Reply envelopes are serialized as either:
  //   * one-element lists containing the successful result as its single
  //     element, or
  //   * three-element lists containing, in order, an error code String, an
  //     error message String, and an error details value.

  /// Creates a [MethodCodec] with UTF-8 encoded JSON method calls and result
  /// envelopes.
  const JSONMethodCodec();

  @override
  ByteData encodeMethodCall(MethodCall call) {
    return const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': call.method,
      'args': call.arguments,
    });
  }

  @override
  MethodCall decodeMethodCall(ByteData methodCall) {
    final dynamic decoded = const JSONMessageCodec().decodeMessage(methodCall);
    if (decoded is! Map)
      throw new FormatException('Expected method call Map, got $decoded');
    final dynamic method = decoded['method'];
    final dynamic arguments = decoded['args'];
    if (method is String)
      return new MethodCall(method, arguments);
    throw new FormatException('Invalid method call: $decoded');
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    final dynamic decoded = const JSONMessageCodec().decodeMessage(envelope);
    if (decoded is! List)
      throw new FormatException('Expected envelope List, got $decoded');
    if (decoded.length == 1)
      return decoded[0];
    if (decoded.length == 3
        && decoded[0] is String
        && (decoded[1] == null || decoded[1] is String))
      throw new PlatformException(
        code: decoded[0],
        message: decoded[1],
        details: decoded[2],
      );
    throw new FormatException('Invalid envelope: $decoded');
  }

  @override
  ByteData encodeSuccessEnvelope(dynamic result) {
    return const JSONMessageCodec().encodeMessage(<dynamic>[result]);
  }

  @override
  ByteData encodeErrorEnvelope({@required String code, String message, dynamic details}) {
    assert(code != null);
    return const JSONMessageCodec().encodeMessage(<dynamic>[code, message, details]);
  }
}

/// [MessageCodec] using the Flutter standard binary encoding.
///
/// Supported messages are acyclic values of these forms:
///
///  * null
///  * [bool]s
///  * [num]s
///  * [String]s
///  * [Uint8List]s, [Int32List]s, [Int64List]s, [Float64List]s
///  * [List]s of supported values
///  * [Map]s from supported values to supported values
///
/// On Android, messages are represented as follows:
///
///  * null: null
///  * [bool]\: `java.lang.Boolean`
///  * [int]\: `java.lang.Integer` for values that are representable using 32-bit
///    two's complement; `java.lang.Long` otherwise
///  * [double]\: `java.lang.Double`
///  * [String]\: `java.lang.String`
///  * [Uint8List]\: `byte[]`
///  * [Int32List]\: `int[]`
///  * [Int64List]\: `long[]`
///  * [Float64List]\: `double[]`
///  * [List]\: `java.util.ArrayList`
///  * [Map]\: `java.util.HashMap`
///
/// On iOS, messages are represented as follows:
///
///  * null: nil
///  * [bool]\: `NSNumber numberWithBool:`
///  * [int]\: `NSNumber numberWithInt:` for values that are representable using
///    32-bit two's complement; `NSNumber numberWithLong:` otherwise
///  * [double]\: `NSNumber numberWithDouble:`
///  * [String]\: `NSString`
///  * [Uint8List], [Int32List], [Int64List], [Float64List]\:
///    `FlutterStandardTypedData`
///  * [List]\: `NSArray`
///  * [Map]\: `NSDictionary`
class StandardMessageCodec implements MessageCodec<dynamic> {
  // The codec serializes messages as outlined below. This format must
  // match the Android and iOS counterparts.
  //
  // * A single byte with one of the constant values below determines the
  //   type of the value.
  // * The serialization of the value itself follows the type byte.
  // * Numbers are represented using the host endianness throughout.
  // * Lengths and sizes of serialized parts are encoded using an expanding
  //   format optimized for the common case of small non-negative integers:
  //   * values 0..253 inclusive using one byte with that value;
  //   * values 254..2^16 inclusive using three bytes, the first of which is
  //     254, the next two the usual unsigned representation of the value;
  //   * values 2^16+1..2^32 inclusive using five bytes, the first of which is
  //     255, the next four the usual unsigned representation of the value.
  // * null, true, and false have empty serialization; they are encoded directly
  //   in the type byte (using _kNull, _kTrue, _kFalse)
  // * Integers representable in 32 bits are encoded using 4 bytes two's
  //   complement representation.
  // * Larger integers are encoded using 8 bytes two's complement
  //   representation.
  // * doubles are encoded using the IEEE 754 64-bit double-precision binary
  //   format.
  // * Strings are encoded using their UTF-8 representation. First the length
  //   of that in bytes is encoded using the expanding format, then follows the
  //   UTF-8 encoding itself.
  // * Uint8Lists, Int32Lists, Int64Lists, and Float64Lists are encoded by first
  //   encoding the list's element count in the expanding format, then the
  //   smallest number of zero bytes needed to align the position in the full
  //   message with a multiple of the number of bytes per element, then the
  //   encoding of the list elements themselves, end-to-end with no additional
  //   type information, using two's complement or IEEE 754 as applicable.
  // * Lists are encoded by first encoding their length in the expanding format,
  //   then follows the recursive encoding of each element value, including the
  //   type byte (Lists are assumed to be heterogeneous).
  // * Maps are encoded by first encoding their length in the expanding format,
  //   then follows the recursive encoding of each key/value pair, including the
  //   type byte for both (Maps are assumed to be heterogeneous).
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

  /// Creates a [MessageCodec] using the Flutter standard binary encoding.
  const StandardMessageCodec();

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null)
      return null;
    final WriteBuffer buffer = new WriteBuffer();
    _writeValue(buffer, message);
    return buffer.done();
  }

  @override
  dynamic decodeMessage(ByteData message) {
    if (message == null)
      return null;
    final ReadBuffer buffer = new ReadBuffer(message);
    final dynamic result = _readValue(buffer);
    if (buffer.hasRemaining)
      throw const FormatException('Message corrupted');
    return result;
  }

  static void _writeSize(WriteBuffer buffer, int value) {
    assert(0 <= value && value <= 0xffffffff);
    if (value < 254) {
      buffer.putUint8(value);
    } else if (value <= 0xffff) {
      buffer.putUint8(254);
      buffer.putUint16(value);
    } else {
      buffer.putUint8(255);
      buffer.putUint32(value);
    }
  }

  static void _writeValue(WriteBuffer buffer, dynamic value) {
    if (value == null) {
      buffer.putUint8(_kNull);
    } else if (value is bool) {
      buffer.putUint8(value ? _kTrue : _kFalse);
    } else if (value is int) {
      if (-0x7fffffff - 1 <= value && value <= 0x7fffffff) {
        buffer.putUint8(_kInt32);
        buffer.putInt32(value);
      } else {
        buffer.putUint8(_kInt64);
        buffer.putInt64(value);
      }
    } else if (value is double) {
      buffer.putUint8(_kFloat64);
      buffer.putFloat64(value);
    } else if (value is String) {
      buffer.putUint8(_kString);
      final List<int> bytes = utf8.encoder.convert(value);
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

  static int _readSize(ReadBuffer buffer) {
    final int value = buffer.getUint8();
    if (value < 254)
      return value;
    else if (value == 254)
      return buffer.getUint16();
    else
      return buffer.getUint32();
  }

  static dynamic _readValue(ReadBuffer buffer) {
    if (!buffer.hasRemaining)
      throw const FormatException('Message corrupted');
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
        // Flutter Engine APIs to use large ints have been deprecated on
        // 2018-01-09 and will be made unavailable.
        // TODO(mravn): remove this case once the APIs are unavailable.
        final int length = _readSize(buffer);
        final String hex = utf8.decoder.convert(buffer.getUint8List(length));
        result = int.parse(hex, radix: 16);
        break;
      case _kFloat64:
        result = buffer.getFloat64();
        break;
      case _kString:
        final int length = _readSize(buffer);
        result = utf8.decoder.convert(buffer.getUint8List(length));
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
        result = <dynamic, dynamic>{};
        for (int i = 0; i < length; i++) {
          result[_readValue(buffer)] = _readValue(buffer);
        }
        break;
      default: throw const FormatException('Message corrupted');
    }
    return result;
  }
}

/// [MethodCodec] using the Flutter standard binary encoding.
///
/// The standard codec is guaranteed to be compatible with the corresponding
/// standard codec for FlutterMethodChannels on the host platform. These parts
/// of the Flutter SDK are evolved synchronously.
///
/// Values supported as method arguments and result payloads are those supported
/// by [StandardMessageCodec].
class StandardMethodCodec implements MethodCodec {
  // The codec method calls, and result envelopes as outlined below. This format
  // must match the Android and iOS counterparts.
  //
  // * Individual values are encoded using [StandardMessageCodec].
  // * Method calls are encoded using the concatenation of the encoding
  //   of the method name String and the arguments value.
  // * Reply envelopes are encoded using first a single byte to distinguish the
  //   success case (0) from the error case (1). Then follows:
  //   * In the success case, the encoding of the result value.
  //   * In the error case, the concatenation of the encoding of the error code
  //     string, the error message string, and the error details value.

  /// Creates a [MethodCodec] using the Flutter standard binary encoding.
  const StandardMethodCodec();

  @override
  ByteData encodeMethodCall(MethodCall call) {
    final WriteBuffer buffer = new WriteBuffer();
    StandardMessageCodec._writeValue(buffer, call.method);
    StandardMessageCodec._writeValue(buffer, call.arguments);
    return buffer.done();
  }

  @override
  MethodCall decodeMethodCall(ByteData methodCall) {
    final ReadBuffer buffer = new ReadBuffer(methodCall);
    final dynamic method = StandardMessageCodec._readValue(buffer);
    final dynamic arguments = StandardMessageCodec._readValue(buffer);
    if (method is String && !buffer.hasRemaining)
      return new MethodCall(method, arguments);
    else
      throw const FormatException('Invalid method call');
  }

  @override
  ByteData encodeSuccessEnvelope(dynamic result) {
    final WriteBuffer buffer = new WriteBuffer();
    buffer.putUint8(0);
    StandardMessageCodec._writeValue(buffer, result);
    return buffer.done();
  }

  @override
  ByteData encodeErrorEnvelope({@required String code, String message, dynamic details}) {
    final WriteBuffer buffer = new WriteBuffer();
    buffer.putUint8(1);
    StandardMessageCodec._writeValue(buffer, code);
    StandardMessageCodec._writeValue(buffer, message);
    StandardMessageCodec._writeValue(buffer, details);
    return buffer.done();
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    // First byte is zero in success case, and non-zero otherwise.
    if (envelope.lengthInBytes == 0)
      throw const FormatException('Expected envelope, got nothing');
    final ReadBuffer buffer = new ReadBuffer(envelope);
    if (buffer.getUint8() == 0)
      return StandardMessageCodec._readValue(buffer);
    final dynamic errorCode = StandardMessageCodec._readValue(buffer);
    final dynamic errorMessage = StandardMessageCodec._readValue(buffer);
    final dynamic errorDetails = StandardMessageCodec._readValue(buffer);
    if (errorCode is String && (errorMessage == null || errorMessage is String) && !buffer.hasRemaining)
      throw new PlatformException(code: errorCode, message: errorMessage, details: errorDetails);
    else
      throw const FormatException('Invalid envelope');
  }
}
