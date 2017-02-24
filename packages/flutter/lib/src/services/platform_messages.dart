// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;

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

/// A named channel for communicating with platform plugins using
/// semi-structured messages.
///
/// Messages are encoded into binary before being sent, and binary messages
/// received are decoded into Dart values. The [MessageCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a FlutterChannel counterpart of this channel on the platform
/// side. The Dart type of messages sent  and received is `dynamic`, but only
/// values supported by the specified [MessageCodec] can be used.
///
/// The channel supports basic message send/receive operations, method
/// invocations, and receipt of event streams. All communication is
/// asynchronous.
///
/// The identity of the channel is given by its name, so two identically named
/// instances of [PlatformChannel] may interfere with each other's
/// communication. Specifically, at most one message handler can be registered
/// with the channel name at any given time.
class PlatformChannel {
  /// Creates a [PlatformChannel] with the specified [name].
  ///
  /// The [codec] used will be [MessageCodec.standard], unless otherwise
  /// specified.
  ///
  /// Neither [name] nor [codec] may be `null`.
  PlatformChannel(this.name, [this.codec = MessageCodec.standard]) {
    assert(name != null);
    assert(codec != null);
  }

  /// The logical channel on which communication happens, not `null`.
  final String name;

  /// The message codec used by this channel, not `null`.
  final MessageCodec codec;

  /// Sends the specified [message] to the platform plugins on this channel.
  ///
  /// Returns a [Future] which completes to the received response, decoded as
  /// a [T] instance, or to a [FormatException], if encoding or decoding fails.
  Future<dynamic> send(dynamic message) async {
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
  void setMessageHandler(Future<dynamic> handler(dynamic message)) {
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
  void setMockMessageHandler(Future<dynamic> handler(dynamic message)) {
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
  /// Returns a [Future] which completes to one of the following:
  ///
  /// * a result (possibly `null`), on successful invocation;
  /// * a [PlatformException], if the invocation failed in the platform plugin;
  /// * a [FormatException], if encoding or decoding failed.
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async {
    assert(method != null);
    return codec.decodeEnvelope(await PlatformMessages.sendBinary(
        name,
        codec.encodeMethodCall(method, arguments),
    ));
  }

  /// Sets up a broadcast stream for receiving events on this channel.
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
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    StreamController<dynamic> controller;
    controller = new StreamController<dynamic>.broadcast(
      onListen: () async {
        PlatformMessages.setBinaryMessageHandler(
          name,
          (ByteData reply) async {
              if (reply == null) {
                controller.close();
              } else {
                try {
                  controller.add(codec.decodeEnvelope(reply));
                } catch (e) {
                  controller.addError(e);
                }
              }
          }
        );
        try {
          await invokeMethod('listen', arguments);
        } catch (e) {
          PlatformMessages.setBinaryMessageHandler(name, null);
          controller.addError(e);
        }
      }, onCancel: () async {
        PlatformMessages.setBinaryMessageHandler(name, null);
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
/// Reply envelopes are binary messages with enough structure that the codec can
/// distinguish between a successful reply and an error. In the former case,
/// the codec must be able to extract the result, possibly `null`. In
/// the latter case, the codec must be able to extract an error code string,
/// a (human-readable) error message string, and a value providing any
/// additional error details, possibly `null`. These data items are used to
/// populate a [PlatformException].
///
/// All operations throw [FormatException], if conversion fails.
abstract class MessageCodec {
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
  static const MessageCodec json = const _JSONCodec();

  /// [MessageCodec] using the Flutter standard binary message encoding.
  ///
  /// The standard codec is guaranteed to be compatible with the corresponding
  /// standard codec for FlutterChannels on the host platform. These two parts
  /// of the Flutter SDK are evolved synchronously.
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
  static const MessageCodec standard = const _StandardCodec();

  /// Encodes the specified [message] in binary.
  ///
  /// Returns `null` if the message is `null`.
  ByteData encodeMessage(dynamic message);

  /// Decodes the specified [message] from binary.
  ///
  /// Returns `null` if the message is `null`.
  dynamic decodeMessage(ByteData message);

  /// Encodes the specified method call in binary.
  ///
  /// The [name] of the method must be non-null. The [arguments] may be `null`.
  ByteData encodeMethodCall(String name, dynamic arguments);

  /// Decodes the specified reply [envelope] from binary.
  ///
  /// Throws [PlatformException], if [envelope] represents an error.
  dynamic decodeEnvelope(ByteData envelope);
}

class _JSONCodec implements MessageCodec {
  const _JSONCodec();

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
}

class _StandardCodec implements MessageCodec {
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

  const _StandardCodec();

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null) {
      return null;
    }
    final _WriteBuffer buffer = new _WriteBuffer();
    _writeValue(buffer, message);
    return buffer.byteData;
  }

  @override
  dynamic decodeMessage(ByteData message) {
    if (message == null) {
      return null;
    }
    final _ReadBuffer buffer = new _ReadBuffer(message);
    final dynamic result = _readValue(buffer);
    if (buffer.hasRemaining)
      throw new FormatException('Message corrupted');
    return result;
  }

  void _writeSize(_WriteBuffer buffer, int value) {
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

  void _writeValue(_WriteBuffer buffer, dynamic value) {
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

  int _readSize(_ReadBuffer buffer) {
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

  dynamic _readValue(_ReadBuffer buffer) {
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
    final _WriteBuffer buffer = new _WriteBuffer();
    _writeValue(buffer, name);
    _writeValue(buffer, arguments);
    return buffer.byteData;
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    // First byte is zero in success case, and non-zero otherwise.
    if (envelope == null || envelope.lengthInBytes == 0)
      throw new FormatException('Expected envelope, got nothing');
    final _ReadBuffer buffer = new _ReadBuffer(envelope);
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

class _WriteBuffer {
  final Uint8Buffer buffer = new Uint8Buffer();

  ByteData _fourBytes;
  Uint8List _fourBytesAsList;
  ByteData _eightBytes;
  Uint8List _eightBytesAsList;

  _WriteBuffer() {
    _fourBytes = new ByteData(4);
    _fourBytesAsList = _fourBytes.buffer.asUint8List();
    _eightBytes = new ByteData(8);
    _eightBytesAsList = _eightBytes.buffer.asUint8List();
  }

  void putUint8(int byte) {
    buffer.add(byte);
  }

  void putInt32(int value) {
    _fourBytes.setInt32(0, value);
    buffer.addAll(_fourBytesAsList);
  }

  void putInt64(int value) {
    _eightBytes.setInt64(0, value);
    buffer.addAll(_eightBytesAsList);
  }

  void putFloat64(double value) {
    _eightBytes.setFloat64(0, value);
    buffer.addAll(_eightBytesAsList);
  }

  void putUint8List(Uint8List list) {
    buffer.addAll(list);
  }

  void putInt32List(Int32List list) {
    _alignTo(4);
    buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 4 * list.length));
  }

  void putInt64List(Int64List list) {
    _alignTo(8);
    buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
  }

  void putFloat64List(Float64List list) {
    _alignTo(8);
    buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
  }

  void _alignTo(int alignment) {
    final int mod = buffer.length % alignment;
    if (mod != 0) {
      for (int i = 0; i < alignment - mod; i++) {
        buffer.add(0);
      }
    }
  }

  ByteData get byteData => buffer.buffer.asByteData();
}

class _ReadBuffer {
  final ByteData data;
  int position = 0;

  _ReadBuffer(this.data);

  int getUint8() {
    return data.getUint8(position++);
  }

  int getInt32() {
    final int value = data.getInt32(position);
    position += 4;
    return value;
  }

  int getInt64() {
    final int value = data.getInt64(position);
    position += 8;
    return value;
  }

  double getFloat64() {
    final double value = data.getFloat64(position);
    position += 8;
    return value;
  }

  Uint8List getUint8List(int length) {
    final Uint8List list = data.buffer.asUint8List(data.offsetInBytes + position, length);
    position += length;
    return list;
  }

  Int32List getInt32List(int length) {
    _alignTo(4);
    final Int32List list = data.buffer.asInt32List(data.offsetInBytes + position, length);
    position += 4 * length;
    return list;
  }

  Int64List getInt64List(int length) {
    _alignTo(8);
    final Int64List list = data.buffer.asInt64List(data.offsetInBytes + position, length);
    position += 8 * length;
    return list;
  }

  Float64List getFloat64List(int length) {
    _alignTo(8);
    final Float64List list = data.buffer.asFloat64List(data.offsetInBytes + position, length);
    position += 8 * length;
    return list;
  }

  void _alignTo(int alignment) {
    final int mod = position % alignment;
    if (mod != 0) {
      position += alignment - mod;
    }
  }

  bool get hasRemaining => position < data.lengthInBytes;
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
