// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

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
    if (message == null) return null;
    return utf8.decoder.convert(message.buffer.asUint8List());
  }

  @override
  ByteData encodeMessage(String message) {
    if (message == null) return null;
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
    if (message == null) return null;
    return const StringCodec().encodeMessage(json.encode(message));
  }

  @override
  dynamic decodeMessage(ByteData message) {
    if (message == null) return message;
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
    if (decoded is! Map) {
      throw new FormatException('Expected method call Map, got $decoded');
    }
    final dynamic method = decoded['method'];
    final dynamic arguments = decoded['args'];
    if (method is String) return new MethodCall(method, arguments);
    throw new FormatException('Invalid method call: $decoded');
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    final dynamic decoded = const JSONMessageCodec().decodeMessage(envelope);
    if (decoded is! List) {
      throw new FormatException('Expected envelope List, got $decoded');
    }
    if (decoded.length == 1) return decoded[0];
    if (decoded.length == 3 &&
        decoded[0] is String &&
        (decoded[1] == null || decoded[1] is String)) {
      throw new PlatformException(
        code: decoded[0],
        message: decoded[1],
        details: decoded[2],
      );
    }
    throw new FormatException('Invalid envelope: $decoded');
  }

  @override
  ByteData encodeSuccessEnvelope(dynamic result) {
    return const JSONMessageCodec().encodeMessage(<dynamic>[result]);
  }

  @override
  ByteData encodeErrorEnvelope(
      {@required String code, String message, dynamic details}) {
    assert(code != null);
    return const JSONMessageCodec()
        .encodeMessage(<dynamic>[code, message, details]);
  }
}
