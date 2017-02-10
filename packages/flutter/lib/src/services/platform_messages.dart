// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

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

typedef Future<ByteData> _PlatformMessageHandler(ByteData message);

/// Sends message to and receives messages from platform plugins.
///
/// See: <https://flutter.io/platform-services/>
class PlatformMessages {
  PlatformMessages._();

  // Handlers for incoming messages from platform plugins.
  static final Map<String, _PlatformMessageHandler> _handlers =
      <String, _PlatformMessageHandler>{};

  // Mock handlers that intercept and respond to outgoing messages.
  static final Map<String, _PlatformMessageHandler> _mockHandlers =
      <String, _PlatformMessageHandler>{};

  static Future<ByteData> _sendPlatformMessage(String channel, ByteData message) {
    final Completer<ByteData> completer = new Completer<ByteData>();
    ui.window.sendPlatformMessage(channel, message, (ByteData reply) {
      try {
        completer.complete(reply);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: 'during a platform message response callback',
        ));
      }
    });
    return completer.future;
  }

  /// Calls the handler registered for the given channel.
  ///
  /// Typically called by [ServicesBinding] to handle platform messages received
  /// from [ui.window.onPlatformMessage].
  ///
  /// To register a handler for a given message channel, see [PlatformChannel].
  static Future<Null> handlePlatformMessage(
        String channel, ByteData data, ui.PlatformMessageResponseCallback callback) async {
    ByteData response;
    try {
      _PlatformMessageHandler handler = _handlers[channel];
      if (handler != null)
        response = await handler(data);
    } catch (exception, stack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: 'during a platform message callback',
      ));
    } finally {
      callback(response);
    }
  }

  /// Send a binary message to the platform plugins on the given channel.
  ///
  /// Returns a [Future] which completes to the received response, undecoded, in
  /// binary form.
  static Future<ByteData> sendBinary(String channel, ByteData message) {
    final _PlatformMessageHandler handler = _mockHandlers[channel];
    if (handler != null)
      return handler(message);
    return _sendPlatformMessage(channel, message);
  }

  /// Send a string message to the platform plugins on the given channel.
  ///
  /// The message is encoded as UTF-8.
  ///
  /// Returns a [Future] which completes to the received response, decoded as a
  /// UTF-8 string, or to an error, if the decoding fails.
  ///
  /// Deprecated, use [PlatformChannel.send] instead.
  @deprecated
  static Future<String> sendString(String channel, String message) async {
    return _decodeUTF8(await sendBinary(channel, _encodeUTF8(message)));
  }

  /// Send a JSON-encoded message to the platform plugins on the given channel.
  ///
  /// The message is encoded as JSON, then the JSON is encoded as UTF-8.
  ///
  /// Returns a [Future] which completes to the received response, decoded as a
  /// UTF-8-encoded JSON representation of a JSON value (a [String], [bool],
  /// [double], [List], or [Map]), or to an error, if the decoding fails.
  ///
  /// Deprecated, use [PlatformChannel.send] instead.
  @deprecated
  static Future<dynamic> sendJSON(String channel, dynamic json) async {
    return _decodeJSON(await sendString(channel, _encodeJSON(json)));
  }

  /// Send a method call to the platform plugins on the given channel.
  ///
  /// Method calls are encoded as a JSON object with two keys, `method` with the
  /// string given in the `method` argument, and `args` with the arguments given
  /// in the `args` optional argument, as a JSON list. This JSON object is then
  /// encoded as a UTF-8 string.
  ///
  /// The response from the method call is decoded as UTF-8, then the UTF-8 is
  /// decoded as JSON. The returned [Future] completes to this fully decoded
  /// response, or to an error, if the decoding fails.
  ///
  /// Deprecated, use [PlatformChannel.invokeMethod] instead.
  @deprecated
  static Future<dynamic> invokeMethod(String channel, String method, [ List<dynamic> args = const <Null>[] ]) {
    return sendJSON(channel, <String, dynamic>{
      'method': method,
      'args': args,
    });
  }

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any.
  ///
  /// The handler's return value, if non-null, is sent as a response, unencoded.
  static void setBinaryMessageHandler(String channel, Future<ByteData> handler(ByteData message)) {
    _handlers[channel] = handler;
  }

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, decoding the data as UTF-8.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any.
  ///
  /// The handler's return value, if non-null, is sent as a response, encoded as
  /// a UTF-8 string.
  ///
  /// Deprecated, use [PlatformChannel.setMessageHandler] instead.
  @deprecated
  static void setStringMessageHandler(String channel, Future<String> handler(String message)) {
    setBinaryMessageHandler(channel, (ByteData message) async {
      return _encodeUTF8(await handler(_decodeUTF8(message)));
    });
  }

  /// Set a callback for receiving messages from the platform plugins on the
  /// given channel, decoding the data as UTF-8 JSON.
  ///
  /// The given callback will replace the currently registered callback for that
  /// channel, if any.
  ///
  /// The handler's return value, if non-null, is sent as a response, encoded as
  /// JSON and then as a UTF-8 string.
  ///
  /// Deprecated, use [PlatformChannel.setMessageHandler] instead.
  @deprecated
  static void setJSONMessageHandler(String channel, Future<dynamic> handler(dynamic message)) {
    setStringMessageHandler(channel, (String message) async {
      return _encodeJSON(await handler(_decodeJSON(message)));
    });
  }

  /// Set a mock callback for intercepting messages from the `send*` methods on
  /// this class, on the given channel, without decoding them.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass `null` as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response, unencoded.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  static void setMockBinaryMessageHandler(String channel, Future<ByteData> handler(ByteData message)) {
    if (handler == null)
      _mockHandlers.remove(channel);
    else
      _mockHandlers[channel] = handler;
  }

  /// Set a mock callback for intercepting messages from the `send*` methods on
  /// this class, on the given channel, decoding them as UTF-8.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass `null` as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response, encoded as
  /// UTF-8.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  ///
  /// Deprecated, use [PlatformChannel.setMockMessageHandler] instead.
  @deprecated
  static void setMockStringMessageHandler(String channel, Future<String> handler(String message)) {
    if (handler == null) {
      setMockBinaryMessageHandler(channel, null);
    } else {
      setMockBinaryMessageHandler(channel, (ByteData message) async {
        return _encodeUTF8(await handler(_decodeUTF8(message)));
      });
    }
  }

  /// Set a mock callback for intercepting messages from the `send*` methods on
  /// this class, on the given channel, decoding them as UTF-8 JSON.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// that channel, if any. To remove the mock handler, pass `null` as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response, encoded as
  /// UTF-8 JSON.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  ///
  /// Deprecated, use [PlatformChannel.setMockMessageHandler] instead.
  @deprecated
  static void setMockJSONMessageHandler(String channel, Future<dynamic> handler(dynamic message)) {
    if (handler == null) {
      setMockStringMessageHandler(channel, null);
    } else {
      setMockStringMessageHandler(channel, (String message) async {
        return _encodeJSON(await handler(_decodeJSON(message)));
      });
    }
  }
}

/// A named channel for communicating with platform plugins.
///
/// [T] is the Dart type of messages sent and received. Messages are encoded
/// into binary before being sent, and binary messages received are decoded
/// into [T] instances. The [MessageCodec] used must be supported by the target
/// platform plugins.
///
/// The channel supports basic message send/receive operations, method
/// invocations with results of type [T], and receipt of message streams with
/// events of type [T]. All communication is asynchronous.
///
/// Method invocation and stream handling involve structured messages to
/// communicate method call arguments, success/error status, and error details.
/// The dart representation of such structured messages are referred to as
/// '[T] expressions', see [MessageCodec] for details.
///
/// The identity of the channel is given by its name, so two identically named
/// instances of [PlatformChannel] may interfere with each other's
/// communication. Specifically, at most one message handler can be registered
/// with the channel name at any given time.
class PlatformChannel<T> {
  /// Creates a [PlatformChannel] with the specified [name] and message [codec].
  PlatformChannel(this.name, this.codec) {
    assert(name != null);
    assert(codec != null);
  }

  /// Creates a [PlatformChannel] with the specified [name] and
  /// the [MessageCodec.standard] codec.
  static PlatformChannel<dynamic> standard(String name) {
    return new PlatformChannel<dynamic>(name, MessageCodec.standard);
  }

  /// Creates a [PlatformChannel] with the specified [name] and
  /// the [MessageCodec.json] codec.
  static PlatformChannel<dynamic> json(String name) {
    return new PlatformChannel<dynamic>(name, MessageCodec.json);
  }

  /// Creates a [PlatformChannel] with the specified [name] and
  /// the [MessageCodec.binary] codec.
  static PlatformChannel<ByteData> binary(String name) {
    return new PlatformChannel<ByteData>(name, MessageCodec.binary);
  }

  /// Creates a [PlatformChannel] with the specified [name] and
  /// the [MessageCodec.string] codec.
  static PlatformChannel<String> string(String name) {
    return new PlatformChannel<String>(name, MessageCodec.string);
  }

  /// The logical channel on which communication happens, not `null`.
  final String name;

  /// The message codec used by this channel, not `null`.
  final MessageCodec<T> codec;

  /// Sends the specified [message] to the platform plugins on this channel.
  ///
  /// Returns a [Future] which completes to the received response, decoded as
  /// a [T] instance, or to a [FormatException], if encoding or decoding fails.
  Future<T> send(T message) async {
    return codec.decodeMessage(
      await PlatformMessages.sendBinary(name, codec.encodeMessage(message))
    );
  }

  /// Sets a callback for receiving messages from the platform plugins on this
  /// channel.
  ///
  /// The given callback will replace the currently registered callback for this
  /// channel's name.
  ///
  /// The handler's return value, if non-null, is sent back to the platform
  /// plugins as a response.
  void setMessageHandler(Future<T> handler(T message)) {
    PlatformMessages.setBinaryMessageHandler(name, (ByteData message) async {
      return codec.encodeMessage(await handler(codec.decodeMessage(message)));
    });
  }

  /// Sets a mock callback for intercepting messages sent on this channel.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// this channel, if any. To remove the mock handler, pass `null` as the
  /// `handler` argument.
  ///
  /// The handler's return value, if non-null, is used as a response.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  void setMockMessageHandler(Future<T> handler(T message)) {
    if (handler == null) {
      PlatformMessages.setMockBinaryMessageHandler(name, null);
    } else {
      PlatformMessages.setMockBinaryMessageHandler(name, (ByteData message) async {
        return codec.encodeMessage(await handler(codec.decodeMessage(message)));
      });
    }
  }

  /// Invokes a [method] on this channel with the specified [arguments].
  ///
  /// The [arguments] must be a valid [T] expression for the [codec] of
  /// this channel.
  ///
  /// Returns a [Future] which completes to one of the following:
  ///
  /// * a result of type [T] (possibly `null`), on successful invocation;
  /// * a [PlatformException], if the invocation failed in the platform plugin;
  /// * a [FormatException], if coding or decoding failed.
  Future<T> invokeMethod(String method, dynamic arguments) async {
    assert(method != null);
    return codec.decodeEnvelope(await PlatformMessages.sendBinary(
        name,
        codec.encodeMethodCall(method, arguments),
    ));
  }

  /// Sets up a broadcast stream for receiving messages on this channel.
  ///
  /// The optional [arguments] map must be a valid [T] expression for the
  /// [codec] of this channel. If present, it means that the stream is
  /// configurable and therefore that multiple streams with different
  /// configurations might need to co-exist. In that case, [arguments] must
  /// contain an `eventChannel` entry with a string value which will be used as
  /// the name of the channel on which events are emitted for the specified
  /// configuration. If [arguments] is `null`, this [PlatformChannel] is used
  /// for events.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  /// * a data event of type [T] (possibly `null`) for each successful event
  /// received from the platform plugin;
  /// * an error event containing a [PlatformException] for each error event
  /// received from the platform plugin;
  /// * an error event containing a [FormatException] for each event received
  /// where decoding fails;
  /// * an error event containing a [PlatformException] or [FormatException]
  /// whenever stream setup fails (stream setup is done only when listener
  /// count changes from 0 to 1).
  ///
  /// Notes for platform plugin implementers:
  ///
  /// Plugins must expose methods named `listen` and `cancel` suitable for
  /// invocations by [invokeMethod]. Both methods are invoked with the specified
  /// [arguments].
  ///
  /// Following the semantics of broadcast streams, `listen` will be called as
  /// the first listener registers with the returned stream, and `cancel` when
  /// the last listener cancels its registration. This pattern may repeat
  /// indefinitely. Platform plugins should consume no stream-related resources
  /// while listener count is zero.
  Stream<T> receiveBroadcastStream([Map<String, dynamic> arguments]) {
    assert(arguments == null || arguments['eventChannel'] is String);
    final String eventChannel = arguments == null ? name : arguments['eventChannel'];
    StreamController<T> controller;
    controller = new StreamController<T>.broadcast(
      onListen: () async {
        PlatformMessages.setBinaryMessageHandler(
          eventChannel,
          (ByteData reply) async {
            try {
              controller.add(codec.decodeEnvelope(reply));
            } catch (e) {
              controller.addError(e);
            }
          }
        );
        try {
          await invokeMethod('listen', arguments);
        } catch (e) {
          PlatformMessages.setBinaryMessageHandler(eventChannel, null);
          controller.addError(e);
        }
      }, onCancel: () async {
        PlatformMessages.setBinaryMessageHandler(eventChannel, null);
        try {
          await invokeMethod('cancel', arguments);
        } catch (exception, stack) {
          FlutterError.reportError(new FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'services library',
            context: 'while de-activating platform stream on channel $name',
          ));
        }
      }
    );
    return controller.stream;
  }
}

/// A message encoding/decoding mechanism with support for method calls and
/// enveloped replies.
///
/// A plain message is represented in Dart using the type [T]. The structured
/// messages needed for method calls and replies are represented in Dart using
/// '[T] expressions' which are acyclic values of these forms:
///
/// * `null`
/// * [T] instances
/// * [String]s
/// * [List]s of [T] expressions
/// * [Map]s from strings to [T] expressions
///
/// The static Dart type of a [T] expression is `dynamic'.
///
/// Reply envelopes are binary messages with enough structure that the codec can
/// distinguish between a successful reply and an error. In the former case,
/// the codec must be able to extract the result, a [T] instance or `null`. In
/// the latter case, the codec must be able to extract an error code string,
/// a (human-readable) error message string, and a [T] expression providing any
/// additional error details. These data items are used to populate a
/// [PlatformException].
///
/// All operations may throw [FormatException] if conversion fail.
abstract class MessageCodec<T> {
  /// [MessageCodec] with unencoded binary messages represented as [ByteData].
  ///
  /// Delegates to [standard] for encoding [ByteData] expressions.
  static const MessageCodec<ByteData> binary = const _BinaryCodec();

  /// [MessageCodec] with UTF-8 encoded [String] messages.
  ///
  /// Delegates to [json] for encoding [String] expressions.
  static const MessageCodec<String> string = const _StringCodec();

  /// [MessageCodec] with UTF-8 encoded JSON messages.
  ///
  /// Supported messages are acyclic values of these forms:
  ///
  /// * `null`
  /// * [bool]s
  /// * [num]s
  /// * [String]s
  /// * [List]s of supported values
  /// * [Map]s from strings to supported values
  ///
  /// Messages thus subsume expressions for this codec.
  static const MessageCodec<dynamic> json = const _JSONCodec();

  /// [MessageCodec] using the Flutter standard binary message encoding.
  ///
  /// The standard codec is guaranteed to be understood by platform plugins
  /// built using the Flutter platform plugin APIs TODO(mravn): reference needed
  /// These two parts of the Flutter SDK are evolved synchronously.
  ///
  /// Supported messages are acyclic values of these forms:
  ///
  /// * `null`
  /// * [bool]s
  /// * [num]s
  /// * [String]s
  /// * [ByteData]s
  /// * [List]s of supported values
  /// * [Map]s from strings to supported values
  ///
  /// Messages thus subsume expressions for this codec.
  static const MessageCodec<dynamic> standard = const _StandardCodec();

  /// Encodes the specified [message] in binary.
  ByteData encodeMessage(T message);

  /// Decodes the specified [message] from binary.
  T decodeMessage(ByteData message);

  /// Encodes the specified method call in binary.
  ///
  /// The [name] of the method must be non-null. The [arguments] must be a
  /// [T] expression.
  ByteData encodeMethodCall(String name, dynamic arguments);

  /// Decodes the specified reply [envelope] from binary.
  ///
  /// Throws [PlatformException], if [envelope] represents an error.
  T decodeEnvelope(ByteData envelope);
}

class _BinaryCodec implements MessageCodec<ByteData> {
  const _BinaryCodec();

  @override
  ByteData encodeMessage(ByteData message) => message;

  @override
  ByteData decodeMessage(ByteData message) => message;

  @override
  ByteData encodeMethodCall(String name, dynamic arguments) {
    return MessageCodec.standard.encodeMethodCall(name, arguments);
  }

  @override
  ByteData decodeEnvelope(ByteData envelope) {
    return MessageCodec.standard.decodeEnvelope(envelope);
  }
}

class _StringCodec implements MessageCodec<String> {
  const _StringCodec();

  @override
  ByteData encodeMessage(String message) => _encodeUTF8(message);

  @override
  String decodeMessage(ByteData message) => _decodeUTF8(message);

  @override
  ByteData encodeMethodCall(String name, dynamic arguments) {
    return MessageCodec.json.encodeMethodCall(name, arguments);
  }

  @override
  String decodeEnvelope(ByteData envelope) {
    return MessageCodec.json.decodeEnvelope(envelope);
  }
}

class _JSONCodec implements MessageCodec<dynamic> {
  const _JSONCodec();

  @override
  ByteData encodeMessage(dynamic message) => _encodeUTF8(_encodeJSON(message));

  @override
  dynamic decodeMessage(ByteData message) => _decodeJSON(_decodeUTF8(message));

  @override
  ByteData encodeMethodCall(String name, dynamic arguments) {
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
}

class _StandardCodec implements MessageCodec<dynamic> {
  static const int _kNull = 0;
  static const int _kTrue = 1;
  static const int _kFalse = 2;
  static const int _kInt32 = 3;
  static const int _kInt64 = 4;
  static const int _kLargeInt = 5;
  // static const int _kFloat32 = 6; // not currently used
  static const int _kFloat64 = 7;
  static const int _kStringFirst = 8;
  static const int _kStringFollowing = 9;
  static const int _kByteData = 10;
  static const int _kList = 11;
  static const int _kMap = 12;

  const _StandardCodec();

  @override
  ByteData encodeMessage(dynamic message) {
    final List<int> buffer = <int>[];
    final Map<String, int> stringIndex = <String, int>{};
    final ByteData fourBytes = new ByteData(4);
    final ByteData eightBytes = new ByteData(8);

    /// Size encoding is optimized for small values, using one byte in most
    /// practical cases, and three or five bytes for larger messages.
    void writeSize(int value) {
      assert(0 <= value && value < 0xffffffff);
      if (value < 254) {
        buffer.add(value);
      }
      else if (value < 0xffff) {
        buffer.add(254);
        buffer.add(value >> 8);
        buffer.add(value & 0xff);
      }
      else {
        buffer.add(255);
        buffer.add(value >> 24);
        buffer.add((value >> 16) & 0xff);
        buffer.add((value >> 8) & 0xff);
        buffer.add(value & 0xff);
      }
    }

    void writeString(String value) {
      int index = stringIndex[value];
      if (index == null) {
        buffer.add(_kStringFirst);
        writeSize(value.length);
        buffer.addAll(UTF8.encoder.convert(value));
        stringIndex[value] = stringIndex.length;
      }
      else {
        buffer.add(_kStringFollowing);
        writeSize(index);
      }
    }

    void writeMessage(dynamic payload) {
      if (payload == null) {
        buffer.add(_kNull);
      } else if (payload is bool) {
        buffer.add(payload ? _kTrue : _kFalse);
      } else if (payload is int) {
        if (-0x7fffffff <= payload && payload < 0x7fffffff) {
          buffer.add(_kInt32);
          fourBytes.setInt32(0, payload);
          buffer.addAll(fourBytes.buffer.asUint8List());
        }
        else if (-0x7fffffffffffffff <= payload && payload < 0x7fffffffffffffff) {
          buffer.add(_kInt64);
          eightBytes.setInt64(0, payload);
          buffer.addAll(eightBytes.buffer.asUint8List());
        }
        else {
          buffer.add(_kLargeInt);
          final List<int> base64 = UTF8.encoder.convert(payload.toRadixString(64));
          writeSize(base64.length);
          buffer.addAll(base64);
        }
      } else if (payload is double) {
        buffer.add(_kFloat64);
        eightBytes.setFloat64(0, payload);
        buffer.addAll(eightBytes.buffer.asUint8List());
      } else if (payload is String) {
        writeString(payload);
      } else if (payload is ByteData) {
        buffer.add(_kByteData);
        writeSize(payload.lengthInBytes);
        buffer.addAll(payload.buffer.asUint8List());
      } else if (payload is List) {
        buffer.add(_kList);
        writeSize(payload.length);
        for (final dynamic item in payload) {
          writeMessage(item);
        }
      } else if (payload is Map<String, dynamic>) {
        buffer.add(_kMap);
        writeSize(payload.length);
        payload.forEach((String key, dynamic value) {
          writeString(key);
          writeMessage(value);
        });
      } else {
        throw new ArgumentError.value(payload);
      }
    }
    writeMessage(message);
    return new Uint8List.fromList(buffer).buffer.asByteData();
  }

  @override
  dynamic decodeMessage(ByteData message) {
    final ByteBuffer buffer = message.buffer;
    final List<String> stringIndex = <String>[];
    int offset = 0;

    /// Size encoding is optimized for small values, using one byte in most
    /// practical cases, and three or five bytes for larger messages.
    int readSize() {
      int value = message.getUint8(offset);
      if (value < 254) {
        offset++;
      } else if (value == 254) {
        value = (message.getUint8(offset + 1) << 8)
              |  message.getUint8(offset + 2);
        offset += 3;
      } else {
        value = (message.getUint8(offset + 1) << 24)
              | (message.getUint8(offset + 2) << 16)
              | (message.getUint8(offset + 3) << 8)
              |  message.getUint8(offset + 4);
        offset += 5;
      }
      return value;
    }

    String readString() {
      switch (message.getUint8(offset)) {
        case _kStringFirst:
          offset++;
          final int length = readSize();
          final String s = UTF8.decoder.convert(buffer.asUint8List(offset, offset + length));
          offset += length;
          stringIndex.add(s);
          return s;
        case _kStringFollowing:
          offset++;
          final int index = readSize();
          return stringIndex[index];
        default: throw new FormatException('Message corrupted');
      }
    }

    dynamic readPayload() {
      if (message.lengthInBytes <= offset)
        throw throw new FormatException('Message corrupted');
      dynamic result;
      switch (message.getUint8(offset)) {
        case _kNull:
          offset++;
          result = null;
          break;
        case _kTrue:
          offset++;
          result = true;
          break;
        case _kFalse:
          offset++;
          result = false;
          break;
        case _kInt32:
          offset++;
          result = message.getInt32(offset);
          offset += 4;
          break;
        case _kInt64:
          offset++;
          result = message.getInt64(offset);
          offset += 8;
          break;
        case _kLargeInt:
          offset++;
          final int length = readSize();
          final String s = UTF8.decoder.convert(buffer.asUint8List(offset, offset + length));
          result = int.parse(s, radix: 64);
          offset += length;
          break;
        case _kFloat64:
          offset++;
          result = message.getFloat64(offset);
          offset += 8;
          break;
        case _kStringFirst:
          result = readString();
          break;
        case _kStringFollowing:
          result = readString();
          break;
        case _kByteData:
          offset++;
          final int length = readSize();
          result = new ByteData.view(buffer, offset, offset += length);
          offset += length;
          break;
        case _kList:
          offset++;
          final int length = readSize();
          result = new List<dynamic>(length);
          for (int i = 0; i < length; i++) {
            result.add(readPayload());
          }
          break;
        case _kMap:
          offset++;
          final int length = readSize();
          result = new Map<String, dynamic>();
          for (int i = 0; i < length; i++) {
            result.put(readString(), readPayload());
          }
          break;
        default: throw new FormatException('Message corrupted');
      }
      return result;
    }
    final dynamic result = readPayload();
    if (offset != message.lengthInBytes)
      throw new FormatException('Message corrupted');
    return result;
  }

  @override
  ByteData encodeMethodCall(String name, dynamic arguments) {
    return encodeMessage(<dynamic>[name, arguments]);
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    // First byte is zero in success case, and non-zero otherwise.
    if (envelope.lengthInBytes == 0)
      throw new FormatException('Expected envelope, got nothing');
    final dynamic content = decodeMessage(new ByteData.view(envelope.buffer, 1));
    if (envelope.getUint8(0) == 0) // success case
      return content;
    if (content is List && content.length == 3 && content[0] is String && content[1] is String)
      throw new PlatformException(code: content[0], message: content[1], details: content[2]);
    else
      throw new FormatException('Invalid envelope: $content');
  }
}

/// Thrown to indicate that a platform interaction resulted in an error.
class PlatformException implements Exception {
  /// Creates a [PlatformException] with the specified error [code] and
  /// [message], both of which must be non-`null`, and with the optional
  /// error [details] which must be a valid T-expression for the [MessageCodec]
  /// involved in the interaction.
  PlatformException({
    @required this.code,
    @required this.message,
    this.details,
  }) {
    assert(code != null);
    assert(message != null);
  }

  /// A non-`null` error code.
  final String code;

  /// A non-`null` human-readable error message.
  final String message;

  /// Custom details about the error, a valid T-expression.
  final dynamic details;

  @override
  String toString() => 'PlatformException($code, $message, $details)';
}
