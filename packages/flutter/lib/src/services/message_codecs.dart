// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;

import 'message_codec.dart';

/// [MessageCodec] with unencoded binary messages represented using [ByteData].
///
/// On Android, messages will be represented using `java.nio.ByteBuffer`.
/// On iOS, messages will be represented using `NSData`.
///
/// When sending outgoing messages from Android, be sure to use direct `ByteBuffer`
/// as opposed to indirect. The `wrap()` API provides indirect buffers by default
/// and you will get empty `ByteData` objects in Dart.
class BinaryCodec implements MessageCodec<ByteData?> {
  /// Creates a [MessageCodec] with unencoded binary messages represented using
  /// [ByteData].
  const BinaryCodec();

  @override
  ByteData? decodeMessage(ByteData? message) => message;

  @override
  ByteData? encodeMessage(ByteData? message) => message;
}

/// [MessageCodec] with UTF-8 encoded String messages.
///
/// On Android, messages will be represented using `java.util.String`.
/// On iOS, messages will be represented using `NSString`.
class StringCodec implements MessageCodec<String?> {
  /// Creates a [MessageCodec] with UTF-8 encoded String messages.
  const StringCodec();

  @override
  String? decodeMessage(ByteData? message) {
    if (message == null)
      return null;
    return utf8.decoder.convert(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
  }

  @override
  ByteData? encodeMessage(String? message) {
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
  ByteData? encodeMessage(dynamic message) {
    if (message == null)
      return null;
    return const StringCodec().encodeMessage(json.encode(message));
  }

  @override
  dynamic decodeMessage(ByteData? message) {
    if (message == null)
      return message;
    return json.decode(const StringCodec().decodeMessage(message)!);
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
    })!;
  }

  @override
  MethodCall decodeMethodCall(ByteData? methodCall) {
    final dynamic decoded = const JSONMessageCodec().decodeMessage(methodCall);
    if (decoded is! Map)
      throw FormatException('Expected method call Map, got $decoded');
    final dynamic method = decoded['method'];
    final dynamic arguments = decoded['args'];
    if (method is String)
      return MethodCall(method, arguments);
    throw FormatException('Invalid method call: $decoded');
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    final dynamic decoded = const JSONMessageCodec().decodeMessage(envelope);
    if (decoded is! List)
      throw FormatException('Expected envelope List, got $decoded');
    if (decoded.length == 1)
      return decoded[0];
    if (decoded.length == 3
        && decoded[0] is String
        && (decoded[1] == null || decoded[1] is String))
      throw PlatformException(
        code: decoded[0] as String,
        message: decoded[1] as String,
        details: decoded[2],
      );
    if (decoded.length == 4
        && decoded[0] is String
        && (decoded[1] == null || decoded[1] is String)
        && (decoded[3] == null || decoded[3] is String))
      throw PlatformException(
        code: decoded[0] as String,
        message: decoded[1] as String,
        details: decoded[2],
        stacktrace: decoded[3] as String,
      );
    throw FormatException('Invalid envelope: $decoded');
  }

  @override
  ByteData encodeSuccessEnvelope(dynamic result) {
    return const JSONMessageCodec().encodeMessage(<dynamic>[result])!;
  }

  @override
  ByteData encodeErrorEnvelope({ required String code, String? message, dynamic details}) {
    assert(code != null);
    return const JSONMessageCodec().encodeMessage(<dynamic>[code, message, details])!;
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
/// Decoded values will use `List<dynamic>` and `Map<dynamic, dynamic>`
/// irrespective of content.
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
///
/// When sending a `java.math.BigInteger` from Java, it is converted into a
/// [String] with the hexadecimal representation of the integer. (The value is
/// tagged as being a big integer; subclasses of this class could be made to
/// support it natively; see the discussion at [writeValue].) This codec does
/// not support sending big integers from Dart.
///
/// The codec is extensible by subclasses overriding [writeValue] and
/// [readValueOfType].
class StandardMessageCodec implements MessageCodec<dynamic> {
  /// Creates a [MessageCodec] using the Flutter standard binary encoding.
  const StandardMessageCodec();

  // The codec serializes messages as outlined below. This format must match the
  // Android and iOS counterparts and cannot change (as it's possible for
  // someone to end up using this for persistent storage).
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
  //   in the type byte (using _valueNull, _valueTrue, _valueFalse)
  // * Integers representable in 32 bits are encoded using 4 bytes two's
  //   complement representation.
  // * Larger integers are encoded using 8 bytes two's complement
  //   representation.
  // * doubles are encoded using the IEEE 754 64-bit double-precision binary
  //   format. Zero bytes are added before the encoded double value to align it
  //   to a 64 bit boundary in the full message.
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
  //
  // The type labels below must not change, since it's possible for this interface
  // to be used for persistent storage.
  static const int _valueNull = 0;
  static const int _valueTrue = 1;
  static const int _valueFalse = 2;
  static const int _valueInt32 = 3;
  static const int _valueInt64 = 4;
  static const int _valueLargeInt = 5;
  static const int _valueFloat64 = 6;
  static const int _valueString = 7;
  static const int _valueUint8List = 8;
  static const int _valueInt32List = 9;
  static const int _valueInt64List = 10;
  static const int _valueFloat64List = 11;
  static const int _valueList = 12;
  static const int _valueMap = 13;

  @override
  ByteData? encodeMessage(dynamic message) {
    if (message == null)
      return null;
    final WriteBuffer buffer = WriteBuffer();
    writeValue(buffer, message);
    return buffer.done();
  }

  @override
  dynamic decodeMessage(ByteData? message) {
    if (message == null)
      return null;
    final ReadBuffer buffer = ReadBuffer(message);
    final dynamic result = readValue(buffer);
    if (buffer.hasRemaining)
      throw const FormatException('Message corrupted');
    return result;
  }

  /// Writes [value] to [buffer] by first writing a type discriminator
  /// byte, then the value itself.
  ///
  /// This method may be called recursively to serialize container values.
  ///
  /// Type discriminators 0 through 127 inclusive are reserved for use by the
  /// base class, as follows:
  ///
  ///  * null = 0
  ///  * true = 1
  ///  * false = 2
  ///  * 32 bit integer = 3
  ///  * 64 bit integer = 4
  ///  * larger integers = 5 (see below)
  ///  * 64 bit floating-point number = 6
  ///  * String = 7
  ///  * Uint8List = 8
  ///  * Int32List = 9
  ///  * Int64List = 10
  ///  * Float64List = 11
  ///  * List = 12
  ///  * Map = 13
  ///  * Reserved for future expansion: 14..127
  ///
  /// The codec can be extended by overriding this method, calling super
  /// for values that the extension does not handle. Type discriminators
  /// used by extensions must be greater than or equal to 128 in order to avoid
  /// clashes with any later extensions to the base class.
  ///
  /// The "larger integers" type, 5, is never used by [writeValue]. A subclass
  /// could represent big integers from another package using that type. The
  /// format is first the type byte (0x05), then the actual number as an ASCII
  /// string giving the hexadecimal representation of the integer, with the
  /// string's length as encoded by [writeSize] followed by the string bytes. On
  /// Android, that would get converted to a `java.math.BigInteger` object. On
  /// iOS, the string representation is returned.
  void writeValue(WriteBuffer buffer, dynamic value) {
    if (value == null) {
      buffer.putUint8(_valueNull);
    } else if (value is bool) {
      buffer.putUint8(value ? _valueTrue : _valueFalse);
    } else if (value is double) {  // Double precedes int because in JS everything is a double.
                                   // Therefore in JS, both `is int` and `is double` always
                                   // return `true`. If we check int first, we'll end up treating
                                   // all numbers as ints and attempt the int32/int64 conversion,
                                   // which is wrong. This precedence rule is irrelevant when
                                   // decoding because we use tags to detect the type of value.
      buffer.putUint8(_valueFloat64);
      buffer.putFloat64(value);
    } else if (value is int) {
      if (-0x7fffffff - 1 <= value && value <= 0x7fffffff) {
        buffer.putUint8(_valueInt32);
        buffer.putInt32(value);
      } else {
        buffer.putUint8(_valueInt64);
        buffer.putInt64(value);
      }
    } else if (value is String) {
      buffer.putUint8(_valueString);
      final Uint8List bytes = utf8.encoder.convert(value);
      writeSize(buffer, bytes.length);
      buffer.putUint8List(bytes);
    } else if (value is Uint8List) {
      buffer.putUint8(_valueUint8List);
      writeSize(buffer, value.length);
      buffer.putUint8List(value);
    } else if (value is Int32List) {
      buffer.putUint8(_valueInt32List);
      writeSize(buffer, value.length);
      buffer.putInt32List(value);
    } else if (value is Int64List) {
      buffer.putUint8(_valueInt64List);
      writeSize(buffer, value.length);
      buffer.putInt64List(value);
    } else if (value is Float64List) {
      buffer.putUint8(_valueFloat64List);
      writeSize(buffer, value.length);
      buffer.putFloat64List(value);
    } else if (value is List) {
      buffer.putUint8(_valueList);
      writeSize(buffer, value.length);
      for (final dynamic item in value) {
        writeValue(buffer, item);
      }
    } else if (value is Map) {
      buffer.putUint8(_valueMap);
      writeSize(buffer, value.length);
      value.forEach((dynamic key, dynamic value) {
        writeValue(buffer, key);
        writeValue(buffer, value);
      });
    } else {
      throw ArgumentError.value(value);
    }
  }

  /// Reads a value from [buffer] as written by [writeValue].
  ///
  /// This method is intended for use by subclasses overriding
  /// [readValueOfType].
  dynamic readValue(ReadBuffer buffer) {
    if (!buffer.hasRemaining)
      throw const FormatException('Message corrupted');
    final int type = buffer.getUint8();
    return readValueOfType(type, buffer);
  }

  /// Reads a value of the indicated [type] from [buffer].
  ///
  /// The codec can be extended by overriding this method, calling super for
  /// types that the extension does not handle. See the discussion at
  /// [writeValue].
  dynamic readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case _valueNull:
        return null;
      case _valueTrue:
        return true;
      case _valueFalse:
        return false;
      case _valueInt32:
        return buffer.getInt32();
      case _valueInt64:
        return buffer.getInt64();
      case _valueFloat64:
        return buffer.getFloat64();
      case _valueLargeInt:
      case _valueString:
        final int length = readSize(buffer);
        return utf8.decoder.convert(buffer.getUint8List(length));
      case _valueUint8List:
        final int length = readSize(buffer);
        return buffer.getUint8List(length);
      case _valueInt32List:
        final int length = readSize(buffer);
        return buffer.getInt32List(length);
      case _valueInt64List:
        final int length = readSize(buffer);
        return buffer.getInt64List(length);
      case _valueFloat64List:
        final int length = readSize(buffer);
        return buffer.getFloat64List(length);
      case _valueList:
        final int length = readSize(buffer);
        final dynamic result = List<dynamic>.filled(length, null, growable: false);
        for (int i = 0; i < length; i++)
          result[i] = readValue(buffer);
        return result;
      case _valueMap:
        final int length = readSize(buffer);
        final dynamic result = <dynamic, dynamic>{};
        for (int i = 0; i < length; i++)
          result[readValue(buffer)] = readValue(buffer);
        return result;
      default: throw const FormatException('Message corrupted');
    }
  }

  /// Writes a non-negative 32-bit integer [value] to [buffer]
  /// using an expanding 1-5 byte encoding that optimizes for small values.
  ///
  /// This method is intended for use by subclasses overriding
  /// [writeValue].
  void writeSize(WriteBuffer buffer, int value) {
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

  /// Reads a non-negative int from [buffer] as written by [writeSize].
  ///
  /// This method is intended for use by subclasses overriding
  /// [readValueOfType].
  int readSize(ReadBuffer buffer) {
    final int value = buffer.getUint8();
    switch (value) {
      case 254:
        return buffer.getUint16();
      case 255:
        return buffer.getUint32();
      default:
        return value;
    }
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
  const StandardMethodCodec([this.messageCodec = const StandardMessageCodec()]);

  /// The message codec that this method codec uses for encoding values.
  final StandardMessageCodec messageCodec;

  @override
  ByteData encodeMethodCall(MethodCall call) {
    final WriteBuffer buffer = WriteBuffer();
    messageCodec.writeValue(buffer, call.method);
    messageCodec.writeValue(buffer, call.arguments);
    return buffer.done();
  }

  @override
  MethodCall decodeMethodCall(ByteData? methodCall) {
    final ReadBuffer buffer = ReadBuffer(methodCall!);
    final dynamic method = messageCodec.readValue(buffer);
    final dynamic arguments = messageCodec.readValue(buffer);
    if (method is String && !buffer.hasRemaining)
      return MethodCall(method, arguments);
    else
      throw const FormatException('Invalid method call');
  }

  @override
  ByteData encodeSuccessEnvelope(dynamic result) {
    final WriteBuffer buffer = WriteBuffer();
    buffer.putUint8(0);
    messageCodec.writeValue(buffer, result);
    return buffer.done();
  }

  @override
  ByteData encodeErrorEnvelope({ required String code, String? message, dynamic details}) {
    final WriteBuffer buffer = WriteBuffer();
    buffer.putUint8(1);
    messageCodec.writeValue(buffer, code);
    messageCodec.writeValue(buffer, message);
    messageCodec.writeValue(buffer, details);
    return buffer.done();
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    // First byte is zero in success case, and non-zero otherwise.
    if (envelope.lengthInBytes == 0)
      throw const FormatException('Expected envelope, got nothing');
    final ReadBuffer buffer = ReadBuffer(envelope);
    if (buffer.getUint8() == 0)
      return messageCodec.readValue(buffer);
    final dynamic errorCode = messageCodec.readValue(buffer);
    final dynamic errorMessage = messageCodec.readValue(buffer);
    final dynamic errorDetails = messageCodec.readValue(buffer);
    final String? errorStacktrace = (buffer.hasRemaining) ? messageCodec.readValue(buffer) as String : null;
    if (errorCode is String && (errorMessage == null || errorMessage is String) && !buffer.hasRemaining)
      throw PlatformException(code: errorCode, message: errorMessage as String, details: errorDetails, stacktrace: errorStacktrace);
    else
      throw const FormatException('Invalid envelope');
  }
}
