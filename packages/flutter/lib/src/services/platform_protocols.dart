// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'platform_messages.dart';

import 'package:flutter/foundation.dart';

/// Protocols for platform communication, implemented on top of
/// [PlatformMessages].
class PlatformProtocols {
  /// Returns a [Future] representing an asynchronous invocation of a named
  /// platform function with JSON-encoded arguments, results, and errors.
  ///
  /// If specified, the optional [args] map must contain valid JSON values
  /// according to [PlatformMessages.sendJSON].
  ///
  /// The platform function must be implemented on the native side by a handler
  /// registered for the specified [channel]. The handler should expect
  /// invocations using envelopes of the form
  ///
  ///     { "name": <function name>,
  ///       "args": <arguments json>
  ///     }
  ///
  /// If [name] is not specified, [channel] is used in its place.
  ///
  /// The native implementation must wrap the result of a successful invocation
  /// in an envelope of the form
  ///
  ///     { "status": "ok",
  ///       "data": <result>
  ///     }
  ///
  /// Similarly, an error must be wrapped in an envelope of the form
  ///
  ///     { "status": "error",
  ///       "message": <human-readable error message>,
  ///       "data": <error details>
  ///     }
  ///
  /// In both cases, `data` is optional and treated as `null` when missing.
  /// The other envelope fields are mandatory. Additional fields, if any, are
  /// silently discarded.
  ///
  /// On successful invocation, the specified [decoder] is used to turn the
  /// result data into a [T] instance (or `null`), which will then complete
  /// the returned future. A `null` decoder is treated as a constantly `null`
  /// function.
  ///
  /// On errors, the returned future will complete with a [PlatformException]
  /// containing the error message and error details data.
  ///
  /// Malformed JSON or envelopes, or data that the [decoder] cannot handle,
  /// will make the returned Future complete with a [FormatException].
  static Future<T> invokeJSONFunction<T>({
    @required String channel,
    String name,
    Map<String, dynamic> args,
    T decoder(dynamic json),
  }) async {
    final dynamic reply = await PlatformMessages.sendJSON(channel, <String, dynamic>{
      'name': name ?? channel,
      'args': args,
    });
    return _interpretJSON<T>(reply, decoder);
  }

  /// Creates a broadcast [Stream] for consuming a named platform stream of
  /// JSON-encoded events.
  ///
  /// The optional [args] map must contain valid JSON values according to
  /// [PlatformMessages.sendJSON]. If [args] is specified, it means that the
  /// stream is configurable and that multiple streams with different
  /// configurations might need to co-exist. In that case, [args] must contain
  /// an `eventChannel` entry with a string value which will be used as the name
  /// of the channel on which events are emitted for the specified configuration.
  /// If [args] is left unspecified, the main [channel] itself is used for events.
  ///
  /// The platform stream must be implemented on the native side by a handler
  /// registered for the specified [channel]. That handler should expect calls
  /// to JSON functions named 'listen' and 'cancel' according to the protocol
  /// of [invokeJSONFunction]. These functions are used to let the native side
  /// know when the Dart stream has registered listeners, see
  /// [StreamController.broadcast]. Both are called with [args] as arguments.
  ///
  /// Following the semantics of broadcast streams, `listen` will be called as
  /// the first listener registers with the returned stream, and `cancel` when
  /// the last listener cancels its registration. This pattern may repeat
  /// indefinitely.
  ///
  /// If the `listen` invocation fails, en error event is emitted on the
  /// returned stream. If the `cancel` invocation fails, the error is
  /// reported through [FlutterError.reportError] as there are no listeners
  /// to receive an error event in that case.
  ///
  /// The native implementation must wrap each data event in an envelope of the
  /// form
  ///
  ///     { 'status': 'ok',
  ///       'data': <data>
  ///     }
  ///
  /// Similarly, an error event must be wrapped in an envelope of the form
  ///
  ///     { 'status': 'error',
  ///       'message': <human-readable error message>,
  ///       'data': <error details>
  ///     }
  ///
  /// For each successful event, the specified [decoder] is used to turn the
  /// data into a [T] instance (or `null`), which is then produced as a data
  /// event by the returned stream. A `null` or missing decoder is treated
  /// as a constantly `null` function.
  ///
  /// On each native error event, the returned stream will produce an error
  /// event with a [PlatformException] containing the error message and error
  /// details data.
  ///
  /// Malformed JSON or envelopes, or data that the [decoder] cannot handle,
  /// will make the returned Stream produce an error event containing a
  /// [FormatException].
  static Stream<T> createJSONBroadcastStream<T>({
    @required String channel,
    Map<String, dynamic> args,
    T decoder(dynamic json),
  }) {
    assert(channel != null);
    assert(args == null || args['eventChannel'] is String);
    final String eventChannel = args == null ? channel : args['eventChannel'];
    StreamController<T> controller;
    controller = new StreamController<T>.broadcast(
      onListen: () async {
        PlatformMessages.setJSONMessageHandler(
          eventChannel,
          (dynamic reply) async {
            try {
              controller.add(_interpretJSON<T>(reply, decoder));
            } catch (e) {
              controller.addError(e);
            }
          }
        );
        try {
          await invokeJSONFunction<Null>(channel: channel, name: 'listen', args: args);
        }
        catch (e) {
          PlatformMessages.setJSONMessageHandler(eventChannel, null);
          controller.addError(e);
        }
      }, onCancel: () async {
        PlatformMessages.setJSONMessageHandler(eventChannel, null);
        try {
          await invokeJSONFunction<Null>(channel: channel, name: 'cancel', args: args);
        }
        catch (exception, stack) {
          FlutterError.reportError(new FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'services library',
            context: 'during de-activating platform stream on channel $channel',
          ));
        }
      }
    );
    return controller.stream;
  }

  static T _interpretJSON<T>(dynamic json, T decoder(dynamic json)) {
    if (json is Map) {
      final dynamic status = json['status'];
      final dynamic message = json['message'];
      final dynamic data = json['data'];
      if (status == 'ok') {
        return decoder?.call(data);
      }
      else if (status is String && message is String) {
        throw new PlatformException(
          status: status,
          message: message,
          details: data,
        );
      }
      else {
        throw new FormatException('Invalid envelope: $json');
      }
    }
    else {
      throw new FormatException('Expected envelope Map, got $json');
    }
  }
}

/// Thrown to indicate that a platform interaction resulted in an error.
class PlatformException implements Exception {
  PlatformException({
    @required this.status,
    @required this.message,
    this.details
  }) {
    assert(status != null);
    assert(message != null);
  }

  /// A non-`null` status string, such as 'error' or 'not found'.
  final String status;

  /// A non-`null` human-readable error message.
  final String message;

  /// A JSON-like value providing custom details about the error, maybe `null`.
  final dynamic details;

  @override
  String toString() => 'PlatformException($status, $message, $details)';
}
